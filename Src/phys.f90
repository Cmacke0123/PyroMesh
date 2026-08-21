module physics

  use params
  use grid

  implicit none

contains


!==========================================================
! Thermal diffusion + wind advection
!
! Solves:
! dT/dt = alpha * laplacian(T) - (wind_x * dT/dx + wind_y * dT/dy)
!
! The advection term uses upwind differencing (picks the neighbor the
! wind is blowing FROM). Central differencing for advection is
! unconditionally unstable with forward-Euler time stepping, so this
! isn't a style choice -- it's required for the scheme to stay stable. Hi
!==========================================================

subroutine step_temperature()

    integer :: i, j
    real(8) :: lap, dTdx, dTdy

    temperature_new = temperature

    ! Safe to parallelize as-is: each (i,j) iteration only ever writes
    ! to its own temperature_new(i,j), reading from the untouched old
    ! temperature(:,:) array. No thread can write a cell another thread
    ! reads, so there's no race regardless of scheduling.
    ! Loop order: j outer, i inner. Fortran arrays are column-major, so
    ! temperature(i,j) and temperature(i+1,j) are adjacent in memory --
    ! i is the fast-varying index. Looping i in the innermost loop keeps
    ! each thread's memory access sequential/cache-friendly; the
    ! original i-outer/j-inner order strided through memory by nx
    ! elements every step, which is the single biggest cost in this
    ! whole file (~4-5x on a large grid in my testing, bigger than the
    ! threading gain).
    !$omp parallel do collapse(2) private(lap, dTdx, dTdy) schedule(static)
    do j = 2, ny-1
        do i = 2, nx-1

            if (state(i,j) /= 2) then

                lap = ( temperature(i+1,j) + temperature(i-1,j) &
                      + temperature(i,j+1) + temperature(i,j-1) &
                      - 4.0d0*temperature(i,j) ) / (dx*dx)

                if (wind_x(i,j) >= 0.0d0) then
                    dTdx = ( temperature(i,j) - temperature(i-1,j) ) / dx
                else
                    dTdx = ( temperature(i+1,j) - temperature(i,j) ) / dx
                end if

                if (wind_y(i,j) >= 0.0d0) then
                    dTdy = ( temperature(i,j) - temperature(i,j-1) ) / dx
                else
                    dTdy = ( temperature(i,j+1) - temperature(i,j) ) / dx
                end if

                temperature_new(i,j) = temperature(i,j) &
                                     + dt * alpha * lap &
                                     - dt * ( wind_x(i,j)*dTdx + wind_y(i,j)*dTdy )

            end if

        end do
    end do
    !$omp end parallel do

    temperature = temperature_new

end subroutine step_temperature



!==========================================================
! Ignition
!
! Converts unburned fuel into burning cells
!
!==========================================================

subroutine ignite_cells()

    integer :: i, j

    ! Safe: each iteration only reads/writes its own cell.
    !$omp parallel do collapse(2) schedule(static)
    do j = 1, ny
        do i = 1, nx

            if (state(i,j) == 0) then

                if (temperature(i,j) > ignition_T .and. &
                    fuel(i,j) > 0.1d0) then

                    state(i,j) = 1

                end if

            end if

        end do
    end do
    !$omp end parallel do

end subroutine ignite_cells



!==========================================================
! Combustion
!
! Consumes fuel and releases heat in burning cells
!
!==========================================================

subroutine burn_cells()

    integer :: i, j

    ! Safe: each iteration only reads/writes its own cell (fuel,
    ! temperature, state at the same (i,j)) -- no neighbor access.
    !$omp parallel do collapse(2) schedule(static)
    do j = 1, ny
        do i = 1, nx

            if (state(i,j) == 1) then

                fuel(i,j) = fuel(i,j) - fuel_rate * dt

                temperature(i,j) = temperature(i,j) &
                                 + heat_release * fuel_rate * dt &
                                 - cooling_rate*(temperature(i,j)-ambient_temperature)*dt


                if (fuel(i,j) <= 0.0d0) then

                    fuel(i,j) = 0.0d0
                    state(i,j) = 2

                end if

            end if

        end do
    end do
    !$omp end parallel do

end subroutine burn_cells



!==========================================================
! Heat transfer from flame to neighboring cells, biased downwind
! ("flame tilt"). The downwind neighbor gets more than flame_heat*dt,
! the upwind neighbor gets less, clamped at zero so a strong wind can't
! push the deposit negative.
!==========================================================

subroutine deposit_heat()

    integer :: i, j
    real(8) :: bias_x, bias_y

    ! NOT embarrassingly parallel like the loops above: this one WRITES
    ! to neighboring cells, not just its own. Two different burning
    ! cells two apart in the same row/column (or otherwise sharing a
    ! neighbor) can target the same temperature(...) element on
    ! different threads at the same time -- e.g. cell i and cell i+2
    ! both write to temperature(i+1,j). Each individual update is
    ! wrapped in "!$omp atomic" so the read-modify-write on that shared
    ! cell can't be torn by another thread; without this it's a real
    ! data race (occasionally dropped updates, not a crash, which makes
    ! it the nasty kind of bug -- it wouldn't show up every run).
    !$omp parallel do collapse(2) private(bias_x, bias_y) schedule(static)
    do j = 1, ny
        do i = 1, nx

            if (state(i,j) == 1) then

                bias_x = flame_tilt * wind_x(i,j)
                bias_y = flame_tilt * wind_y(i,j)

                if (i > 1) then
                    !$omp atomic update
                    temperature(i-1,j) = temperature(i-1,j) &
                                       + max(0.0d0, flame_heat*dt*(1.0d0 - bias_x))
                end if

                if (i < nx) then
                    !$omp atomic update
                    temperature(i+1,j) = temperature(i+1,j) &
                                       + max(0.0d0, flame_heat*dt*(1.0d0 + bias_x))
                end if

                if (j > 1) then
                    !$omp atomic update
                    temperature(i,j-1) = temperature(i,j-1) &
                                       + max(0.0d0, flame_heat*dt*(1.0d0 - bias_y))
                end if

                if (j < ny) then
                    !$omp atomic update
                    temperature(i,j+1) = temperature(i,j+1) &
                                       + max(0.0d0, flame_heat*dt*(1.0d0 + bias_y))
                end if

            end if

        end do
    end do
    !$omp end parallel do

end subroutine deposit_heat


end module physics
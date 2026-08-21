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
! unconditionally unstable. 
!==========================================================

subroutine step_temperature()

    integer :: i, j
    real(8) :: lap, dTdx, dTdy

    temperature_new = temperature

    ! Safe to parallelize as-is: each (i,j) iteration only ever writes
    ! to its own temperature_new(i,j), reading from the untouched old
    ! temperature(:,:) array. No thread can write a cell another thread
    ! reads, so there's no race regardless of scheduling.
    !$omp parallel do collapse(2) private(lap, dTdx, dTdy) schedule(static)
    do i = 2, nx-1
        do j = 2, ny-1

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
!==========================================================

subroutine ignite_cells()

    integer :: i, j

    ! Safe: each iteration only reads/writes its own cell.
    !$omp parallel do collapse(2) schedule(static)
    do i = 1, nx
        do j = 1, ny

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
!==========================================================

subroutine burn_cells()

    integer :: i, j

    ! Safe: each iteration only reads/writes its own cell (fuel,
    ! temperature, state at the same (i,j)) -- no neighbor access.
    !$omp parallel do collapse(2) schedule(static)
    do i = 1, nx
        do j = 1, ny

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

    !$omp parallel do collapse(2) private(bias_x, bias_y) schedule(static)
    do i = 1, nx
        do j = 1, ny

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
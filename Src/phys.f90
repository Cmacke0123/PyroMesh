module physics

  use params
  use grid

  implicit none

contains


!==========================================================
! Thermal diffusion
!
! Solves:
! dT/dt = alpha * laplacian(T)
!
!==========================================================

subroutine step_temperature()

    integer :: i, j
    real(8) :: lap

    temperature_new = temperature

    do i = 2, nx-1
        do j = 2, ny-1

            if (state(i,j) /= 2) then

                lap = ( temperature(i+1,j) + temperature(i-1,j) &
                      + temperature(i,j+1) + temperature(i,j-1) &
                      - 4.0d0*temperature(i,j) ) / (dx*dx)

                temperature_new(i,j) = temperature(i,j) &
                                     + dt * alpha * lap

            end if

        end do
    end do

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

end subroutine ignite_cells



!==========================================================
! Combustion
!
! Consumes fuel and releases heat in burning cells
!
!==========================================================

subroutine burn_cells()

    integer :: i, j

    do i = 1, nx
        do j = 1, ny

            if (state(i,j) == 1) then

                fuel(i,j) = fuel(i,j) - fuel_rate * dt

                temperature(i,j) = temperature(i,j) &
                                 + heat_release * fuel_rate * dt


                if (fuel(i,j) <= 0.0d0) then

                    fuel(i,j) = 0.0d0
                    state(i,j) = 2

                end if

            end if

        end do
    end do

end subroutine burn_cells



!==========================================================
! Heat transfer from flame to neighboring cells
!
!==========================================================

subroutine deposit_heat()

    integer :: i, j

    do i = 1, nx
        do j = 1, ny

            if (state(i,j) == 1) then

                if (i > 1) then
                    temperature(i-1,j) = temperature(i-1,j) &
                                       + flame_heat*dt
                end if

                if (i < nx) then
                    temperature(i+1,j) = temperature(i+1,j) &
                                       + flame_heat*dt
                end if

                if (j > 1) then
                    temperature(i,j-1) = temperature(i,j-1) &
                                       + flame_heat*dt
                end if

                if (j < ny) then
                    temperature(i,j+1) = temperature(i,j+1) &
                                       + flame_heat*dt
                end if

            end if

        end do
    end do

end subroutine deposit_heat


end module physics
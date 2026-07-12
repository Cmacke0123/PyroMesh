module physics
  use params
  use grid
  implicit none

contains

  subroutine step_temperature()

    integer :: i, j
    real(8) :: lap

    T_new = T

    do i = 2, nx-1
      do j = 2, ny-1

        if (state(i,j) /= 2) then

          ! Laplacian (finite difference)
          lap = (T(i+1,j) + T(i-1,j) + T(i,j+1) + T(i,j-1) - 4.0*T(i,j)) / (dx*dx)

          T_new(i,j) = T(i,j) + dt * alpha * lap

        end if

      end do
    end do

    T = T_new

  end subroutine step_temperature


  subroutine combustion()

    integer :: i, j

    do i = 1, nx
      do j = 1, ny

        if (state(i,j) == 0 .and. T(i,j) > ignition_T .and. fuel(i,j) > 0.1) then
          state(i,j) = 1
        end if

        if (state(i,j) == 1) then
          fuel(i,j) = fuel(i,j) - fuel_rate * dt
          T(i,j) = T(i,j) + heat_release * fuel_rate * dt

          if (fuel(i,j) <= 0.0) then
            state(i,j) = 2
            fuel(i,j) = 0.0
          end if
        end if

      end do
    end do

  end subroutine combustion

end module physics
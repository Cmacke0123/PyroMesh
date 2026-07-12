module physics
  use params
  use grid
  implicit none

contains

  subroutine step_temperature()

    integer :: i, j
    real(8) :: lap

    temperature_new = temperature

    do i = 2, nx-1
      do j = 2, ny-1

        if (state(i,j) /= 2) then

          ! Laplacian (finite difference)
          lap = (temperature(i+1,j) + temperature(i-1,j) + temperature(i,j+1) + temperature(i,j-1) - 4.0*temperature(i,j)) / (dx*dx)

          temperature_new(i,j) = temperature(i,j) + dt * alpha * lap

        end if

      end do
    end do

    temperature = temperature_new

  end subroutine step_temperature

subroutine combustion()


    
    integer :: i, j
    print*, "Entering combustion subroutine"
    ! First: ignite cells
    do i = 1, nx
      do j = 1, ny

      if (temperature(i,j) > ignition_T) then
        print*, "HOT:", i, j, temperature(i,j), &
                 fuel(i,j), state(i,j), ignition_T
      end if

      if (state(i,j) == 0 .and. &
        temperature(i,j) > ignition_T .and. &
        fuel(i,j) > 0.1) then

        print *, "IGNITING:", i, j
        state(i,j)=1

      end if

        if (state(i,j) == 0 .and. temperature(i,j) > 800.0) then
    print *, "CHECK", i, j, &
             temperature(i,j), &
             ignition_T, &
             fuel(i,j), &
             state(i,j)
          end if

        if (state(i,j) == 0 .and. &
            temperature(i,j) > ignition_T .and. &
            fuel(i,j) > 0.1) then

            print *, "IGNITE", i, j, temperature(i,j)
            state(i,j) = 1

        end if

      end do
    end do


    ! Second: burn and heat surroundings
    do i = 1, nx
      do j = 1, ny

        if (state(i,j) == 1) then

          fuel(i,j) = fuel(i,j) - fuel_rate * dt

          temperature(i,j) = temperature(i,j) + &
                             heat_release * fuel_rate * dt

          if (i > 1)   temperature(i-1,j) = temperature(i-1,j) + flame_heat*dt
          if (i < nx)  temperature(i+1,j) = temperature(i+1,j) + flame_heat*dt
          if (j > 1)   temperature(i,j-1) = temperature(i,j-1) + flame_heat*dt
          if (j < ny)  temperature(i,j+1) = temperature(i,j+1) + flame_heat*dt

          if (fuel(i,j) <= 0.0) then
            state(i,j) = 2
            fuel(i,j) = 0.0
          end if

        end if

      end do
    end do

end subroutine combustion
end module physics
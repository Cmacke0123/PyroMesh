program wildfire
  use params
  use grid
  use physics
  implicit none

  integer :: t

  call init_grid()

  do t = 1, nt

    call step_temperature()
    call combustion()

    if (mod(t,10) == 0) then
      call write_output(t)
    end if

  end do

end program wildfire
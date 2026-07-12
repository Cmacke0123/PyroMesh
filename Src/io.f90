module io
  use params
  use grid
  implicit none

contains

  subroutine write_output(t)
    integer, intent(in) :: t
    integer :: i, j
    character(len=30) :: fname
    integer :: unit

    write(fname,'("fire_",I4.4,".dat")') t
    open(newunit=unit, file=fname)

    do i = 1, nx
      do j = 1, ny
        write(unit,*) i, j, T(i,j), fuel(i,j), state(i,j)
      end do
    end do

    close(unit)

  end subroutine write_output

end module io
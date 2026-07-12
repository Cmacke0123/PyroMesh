module grid
  use params
  implicit none

  real(8), allocatable :: T(:,:), T_new(:,:)
  real(8), allocatable :: fuel(:,:)
  integer, allocatable :: state(:,:)

contains

  subroutine init_grid()
    integer :: i, j

    allocate(T(nx,ny), T_new(nx,ny))
    allocate(fuel(nx,ny))
    allocate(state(nx,ny))

    T = 300.0
    fuel = 1.0
    state = 0   ! 0 = unburned, 1 = burning, 2 = burned

    ! ignition seed
    do i = nx/2-2, nx/2+2
      do j = ny/2-2, ny/2+2
        T(i,j) = 900.0
        fuel(i,j) = 0.0
        state(i,j) = 1
      end do
    end do

  end subroutine init_grid

end module grid
module banner
  implicit none
contains

  subroutine print_banner()

    print *, "===================================================="
    print *, "    ____                  __  __           _     "
    print *, "   |  _ \ _   _ _ __ ___ |  \/  | ___  ___| |__  "
    print *, "   | |_) | | | | '__/ _ \| |\/| |/ _ \/ __| '_ \ "
    print *, "   |  __/| |_| | | | (_) | |  | |  __/\__ \ | | |"
    print *, "   |_|    \__, |_|  \___/|_|  |_|\___||___/_| |_|"
    print *, "          |___/                                  "
    print *, ""
    print *, "        Physics-Informed Wildfire Spread Model"
    print *, "     Hybrid Eulerian-Lagrangian (PIC-inspired) Grid"
    print *, ""
    print *, "  Author  : Connor MacKenzie"
    print *, "  (c) 2026 Connor MacKenzie. All rights reserved."
    print *, "===================================================="
    print *, ""

  end subroutine print_banner

end module banner


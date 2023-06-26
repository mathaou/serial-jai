#scope_module

tcflag_t :: u64;
speed_t :: u64;
cc_t :: u8;

CRTSCTS :: 0x80000000;

ccflags :: enum {
	B0;
	B50;
	B75;
	B110;
	B134;
	B150;
	B200;
	B300;
	B600;
	B1200;
	B1800;
	B2400;
	B4800;
	B9600;
	B19200;
	B38400;
}

c_cc_chars :: enum {
	VINTR;
	VQUIT;
	VERASE;
	VKILL;
	VEOF;
	VTIME;
	VMIN;
	VSWTC;
	VSTART;
	VSTOP;
	VSUSP;
	VEOL;
	VREPRINT;
	VDISCARD;
	VWERASE;
	VLNEXT;
	VEOL2;
}

c_iflag_bits :: enum_flags {
	IGNBRK;  /* Ignore break condition.  */
	BRKINT; /* Signal interrupt on break.  */
	IGNPAR; /* Ignore characters with parity errors.  */
	PARMRK; /* Mark parity and framing errors.  */
	INPCK;  /* Enable input parity check.  */
	ISTRIP; /* Strip 8th bit off characters.  */
	INLCR;  /* Map NL to CR on input.  */
	IGNCR;  /* Ignore CR.  */
	ICRNL;  /* Map CR to NL on input.  */
	IUCLC;  /* Map uppercase characters to lowercase on input
	                            (not in POSIX).  */
	IXON;  /* Enable start/stop output control.  */
	IXANY;  /* Enable any character to restart output.  */
	IXOFF;  /* Enable start/stop input control.  */
	IMAXBEL;/* Ring bell when input queue is full
	                            (not in POSIX).  */
	IUTF8;  /* Input is UTF8 (not in POSIX).  */
}

c_oflag_bits :: enum_flags {
	OPOST :: 1;  /* Post-process output.  */
	OLCUC;  /* Map lowercase characters to uppercase on output.
	                            (not in POSIX).  */
	ONLCR;  /* Map NL to CR-NL on output.  */
	OCRNL;  /* Map CR to NL on output.  */
	ONOCR;  /* No CR output at column 0.  */
	ONLRET; /* NL performs CR function.  */
	OFILL;  /* Use fill characters for delay.  */
	OFDEL;  /* Fill is DEL.  */
	VTDLY :: 0x4000;  /* Select vertical-tab delays:  */
	VT0 :: 0;  /* Vertical-tab delay type 0.  */
	VT1 :: 0x4000;  /* Vertical-tab delay type 1.  */
}

c_cflag_bits :: enum #specified {
	CSIZE 	:: 0x030;
	CS5 	:: 0x000;
	CS6 	:: 0x010;
	CS7 	:: 0x020;
	CS8 	:: 0x030;
	CSTOPB 	:: 0x040;
	CREAD 	:: 0x080;
	PARENB 	:: 0x100;
	PARODD 	:: 0x200;
	HUPCL 	:: 0x400;
	CLOCAL 	:: 0x800;
}

c_lflag_bits :: enum_flags {
	ISIG :: 1;   /* Enable signals.  */
	ICANON;   /* Canonical input (erase and kill processing).  */
	XCASE;
	ECHO;   /* Enable echo.  */
	ECHOE;   /* Echo erase character as error-correcting
	                             backspace.  */
	ECHOK;   /* Echo KILL.  */
	ECHONL;   /* Echo NL.  */
	NOFLSH;   /* Disable flush after interrupt or quit.  */
	TOSTOP;   /* Send SIGTTOU for background output.  */
	IEXTEN :: 0x8000;   /* Enable implementation-defined input
	                             processing.  */
}

baud_rate :: enum {
	B57600 :: 0x1001;
	B115200;
	B230400;
	B460800;
	B500000;
	B576000;
	B921600;
	B1000000;
	B1152000;
	B1500000;
	B2000000;
	B2500000;
	B3000000;
	B3500000;
	B4000000;
}

tcflow_flags :: enum {
	TCOOFF;
	TCOON;
	TCIOFF;
	TCION;
}

tcflush_flags :: enum {
	TCIFLUSH;
	TCOFLUSH;
	TCIOFLUSH;
}

tcsetaddr_flags :: enum {
	TCSANOW;
	TCSADRAIN;
	TCSAFLUSH;
}

NCCS :: 32;

termios :: struct {
	c_iflag: tcflag_t;      /* input modes */
   	c_oflag: tcflag_t;      /* output modes */
   	c_cflag: tcflag_t;      /* control modes */
   	c_lflag: tcflag_t;      /* local modes */
   	c_line: cc_t;
	c_cc: [NCCS]cc_t;   	/* special characters */
}

#scope_file

libc :: #system_library "libc";

#scope_module

serial_config :: struct {
	br: baud_rate;
	parity: bool;
	two_stop_bits: bool;
	bits: c_cflag_bits;
	hardware_flow_control: bool;
	software_flow_control: bool;
	canonical: bool; // does a newline mean we get a read
	echo: bool;
	raw: bool;
	minimum_characters: u8;
	timeout: u8;
}

set_interface_attributes :: (fd: int, config: *serial_config) -> bool {
        tty: termios;
        
        if (tcgetattr(fd, *tty)) {
			perror("tcgetattr");
			return false;
        }
        
        using c_cflag_bits;
        using c_iflag_bits;
        using c_lflag_bits;
        using c_oflag_bits;
        using c_cc_chars;
        using tcflush_flags;
        using tcsetaddr_flags;
        
        speed := config.br;
        
        set_flag :: (flag: *tcflag_t, val: $T) {
        	<<flag |= xx val;
        }
        
        clear_flag :: (flag: *tcflag_t, val: $T) {
        	<<flag &= xx ~val;
        }
        
        cfsetospeed (*tty, xx speed);
        cfsetispeed (*tty, xx speed);
        
        if config.parity {
        	set_flag(*tty.c_cflag, PARENB);
        } else {
        	clear_flag(*tty.c_cflag, PARENB);
        }
        
        if config.two_stop_bits {
        	set_flag(*tty.c_cflag, CSTOPB);
        } else {
        	clear_flag(*tty.c_cflag, CSTOPB);
        }
        
        clear_flag(*tty.c_cflag, CSIZE);
        
        if config.bits == {
        	case CS5;
        		#through;
        	case CS6;
        		#through;
        	case CS7;
        		#through;
        	case CS8;
				set_flag(*tty.c_cflag, CS8);
        	case; 
        		print("invalid bits flag passed to serial port config");
        		assert(false);
        }
        
        if config.hardware_flow_control {
        	print("enable hardware flow control\n");
        	tty.c_cflag |= xx CRTSCTS;
        } else {
        	print("disable hardware flow control\n");
        	tty.c_cflag &= xx ~CRTSCTS;
        }
        
        // this is pretty much guranteed to be set
        tty.c_cflag |= xx (CREAD | CLOCAL);
        
        if config.canonical {
        	set_flag(*tty.c_lflag, ICANON);
        } else {
        	clear_flag(*tty.c_lflag, ICANON);
        }
        
        if config.echo {
        	set_flag(*tty.c_lflag, ECHO);
        	set_flag(*tty.c_lflag, ECHOE);
        	set_flag(*tty.c_lflag, ECHONL);
        } else {
        	clear_flag(*tty.c_lflag, ECHO);
        	clear_flag(*tty.c_lflag, ECHOE);
        	clear_flag(*tty.c_lflag, ECHONL);
        }
		
		// this is always off for serial
		tty.c_lflag &= xx ~ISIG; // Disable interpretation of INTR, QUIT and SUSP
		
		if config.software_flow_control {
			print("enable software flow control\n");
			tty.c_iflag |= xx (IXON | IXOFF | IXANY); // Turn off s/w flow ctrl
		} else {
			print("disable software flow control\n");
			tty.c_iflag &= xx ~(IXON | IXOFF | IXANY); // Turn off s/w flow ctrl
		}
		
		if config.raw {
			// just raw data, no special handling of bytes for input and output
			tty.c_iflag &= xx ~(IGNBRK|BRKINT|PARMRK|ISTRIP|INLCR|IGNCR|ICRNL);
			tty.c_oflag &= xx ~OPOST; // Prevent special interpretation of output bytes (e.g. newline chars)
			tty.c_oflag &= xx ~ONLCR; // Prevent conversion of newline to carriage return/line feed
	        cfmakeraw(*tty);
		}
	
		/*
VMIN = 0, VTIME = 0: No blocking, return immediately with what is available
VMIN > 0, VTIME = 0: This will make read() always wait for bytes (exactly how many is determined by VMIN), so read() could block indefinitely.
VMIN = 0, VTIME > 0: This is a blocking read of any number of chars with a maximum timeout (given by VTIME). read() will block until either any amount of data is available, or the timeout occurs. This happens to be my favourite mode (and the one I use the most).
VMIN > 0, VTIME > 0: Block until either VMIN characters have been received, or VTIME after first character has elapsed. Note that the timeout for VTIME does not begin until the first character is received.
		*/
		
	    tty.c_cc[VMIN] = xx config.minimum_characters;
	    tty.c_cc[VTIME] = xx config.timeout;
        
		
		tcflush(fd, xx TCIFLUSH);
		if (tcsetattr(fd, xx TCSANOW, *tty)) {
			perror("tcsetattr failed");
			return false;
		}
        
        return true;
}

tcgetattr :: (fd: int, termios_p: *termios) -> int #foreign libc;
tcsetattr :: (fd: int, optional_actions: int,
             termios_p: *termios) -> int #foreign libc;

tcsendbreak :: (fd: int, duration: int) -> int #foreign libc;
tcdrain :: (fd: int) -> int #foreign libc;
tcflush :: (fd: int, queue_selector: int) -> int #foreign libc;
tcflow :: (fd: int, action: int) -> int #foreign libc;

cfmakeraw :: (termios_p: *termios) #foreign libc;

cfgetispeed :: (termios_p: *termios) -> speed_t #foreign libc;
cfgetospeed :: (termios_p: *termios) -> speed_t #foreign libc;

cfsetispeed :: (termios_p: *termios, speed: speed_t) -> int #foreign libc;
cfsetospeed :: (termios_p: *termios, speed: speed_t) -> int #foreign libc;
cfsetspeed :: (termios_p: *termios, speed: speed_t) -> int #foreign libc;

#import "Basic";
#import "POSIX";
#import "Thread";
#import "String";

#load "../termios.jai";

PORT :: "/dev/ttyUSB0";

shared_state :: struct {
	fd: int;
	buffer: *[..]string;
}

// example function to read a single line
// canonical mode means this kind of happens implicitly. This example is for interfacing with
// a shell-like environment like uboot or bash
read_from_port :: (fd: int) -> string #must, bool {
	terminate := false;
	
	buffer_length :: 256;
	buffer := alloc(buffer_length + 1);
	memset(buffer, 0, buffer_length + 1);

	bytes := read(xx fd, buffer, buffer_length);

	if bytes < 0 {
		perror("error reading");
		return "", false;
	} else if bytes == 0 {
		return "", false;
	}
		
	data := to_string(buffer);
	if (ends_with_nocase(data, "\n")) {
  		// print(data);
		return data, true;
	}
	
	return "", false;
}

// output to port
write_to_port :: (fd: int, data: string) -> bool {
    buffer := data;
    assert(buffer.count >= 0);

    while buffer.count > 0 {
        written := write(xx fd, buffer.data, xx buffer.count);

        if (written == -1) {
            perror("could not write data");
            return false;
        }

        buffer.data += written;
        buffer.count -= written;
    }

    return true;
}

// just read forever on a thread
console :: (thread: *Thread) -> s64 {
	ss := cast(*shared_state) thread.data;

	while true {
		line, success := read_from_port(ss.fd);
		if success {
			array_add(ss.buffer, line);
		}
	}

	return 0;
}

main :: () {
	port := open(PORT.data, O_RDWR | O_NOCTTY);
	defer close(port);
	if port == -1 {
		perror("could not open port");
		return;
	}
	
	if !set_interface_attributes(port, *serial_config.{
		br = baud_rate.B115200,  // 115200 baud
		bits = c_cflag_bits.CS8, // 8 bits
		raw = true,
	}) {
		return;
	}

	thread: Thread;
	// this is going to hold all of our read data for whatever purpose
	buffer: [..]string;

	ss: shared_state;
	ss.buffer = *buffer;
	ss.fd = port;

	thread_init(*thread, console);
	thread.data = *ss;
	thread_start(*thread);

	while true {
		// do some logic and ocassionally
		write_to_port(port, "wassup\n");
		// should be trivial at this point to read user input from stdin and create a minimal serial
		// console!
	}
}

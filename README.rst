Computercraft Unified Operating System
======================================

CHANGES CHANGES CHANGES

Goals
-----

CUOS is designed to provide a smooth experience for command-line usage as well
as the programming of computers in Computercraft.

CUOS has the following important design goals:

- *Smooth single-user experience*. All machines are workstations, and are
  either running services, or are accessible to the current user.
- *Simple abstractions on top of hardware*. All hardware devices are
  represented as files on the file-system which contain executable Lua code.
- *Scriptable Shell*. CUOS implements shell scripts, to make running simple
  commands easier.
  
Design
------

execfile
  The *execfile* is a key component of CUOS, and they are meant to be an 
  analogue to the "device files" of Unix. Loading them produces Lua objects
  which describe the device.

The file-system is a key organizational component of CUOS. Instead of there
being an explicit set of APIs for getting information about the printer, or
the wireless modem, etc., there is instead a directory called ``/dev`` which
contains execfiles which can be loaded to get information about that
device.

A Typical Execfile
~~~~~~~~~~~~~~~~~~

A typical execfile detailing a peripheral contains the following body:::

    return {
        side = "left",
        type = "modem",
        methods = ...
    }

The value for *side* can be:

- "left", "right", "top", "bottom", "front", "back" to indicate a real
  peripheral attached to the computer.
- ``nil`` indicates an API which is provided by CUOS, and not any real
  device.

The value for *type* can be:

- "modem", "printer", etc. to indicate a hardware device
- "virtual" to indicate an API provided by CUOS

The value for *methods* is a table of functions which indicate the
functionality available for that peripheral.

/dev
~~~~

``/dev`` contains a list of execfiles. Note that the *S* in the device name
is a side: L (left), R (right), T (top), U (under, or *bottom*), F (front), B (back).

- ``/dev/modemS`` indicates a modem device.
- ``/dev/printerS`` indicates a printer device.
- ``/dev/computerS`` indicates a computer device.
- ``/dev/commandS`` indicates a command block.
- ``/dev/peripherals`` can contain the files *left*, *right*, 
  *front*, *back*, *top* and *bottom* describing the hardware devices
  connected to the machine. These are equivalent to the devices under 
  ``/dev`` - for example, if a modem is on the left, then 
  ``/dev/peripherals/left`` is equivalent to ``/dev/modemL``.

The cuos Module
~~~~~~~~~~~~~~~

The ``cuos`` module has the following API:

- ``cuos.execute(func, ...)`` schedules a particular function to be run as a
  process. This is essentially how CUOS multitakss - you should have one of
  these in every program that you write, so that CUOS can run other programs
  while you're program waits for events. This is inteded for user programs,
  because it waits until the given function has stopped executing.
- ``cuos.daemon(func, ...)`` schedules a particular function to be run.
  This is the same as ``cuos.execute``, but it returns the coroutine used to
  run the given function, instead of waiting for it to exit. This is meant to
  be used for background services.
- ``cuos.run_script(filename)`` runs a shell script, a sequence of commands
  which would otherwise be entered into the shell interactively.
- ``cuos.import(library, [force])`` loads a module from the directory ``/lib``.
  This is basically like ``os.loadAPI``, but it fixes issus when files ending
  in ``.lua`` are imported. Also, it does import caching unless you tell it not
  to by setting the *force* argument to ``true``.
- ``cuos.deport(library)`` is the inverse of ``cuos.import``.
- ``cuos.dev(filename)`` opens up the given execfile, and returns its
  contents (or ``nil`` if the file doesn't exist).
- ``cuos.get_peripheral(type)`` gets the path to the execfile for a given 
  peripheral type, or returns ``nil`` - for example, 
  ``cuos.get_periphal('modem')`` could return ``/dev/modemT``.
- ``cuos.run_shell()`` executes a shell which is similar to the CraftOS shell.
- ``cuos.scheduler()`` is intended only for use by the operating system - it
  dispatches events to processes.

In addition, the ``cuos`` module has the attribute ``cuos.shell``, which is
what programs should use instead of accessing the ``shell`` module directly.

(This is because they aren't "controlling" the terminal").

The hotplug Module
~~~~~~~~~~~~~~~~~~

The ``hotplug`` module manages the ``/dev`` hierarchy. It is not inteded for
use by user programs - it is documented here for completeness.

- ``hotplug.load_devices`` does a sweep of all the peripherals, and constructs
  the ``/dev`` hierarchy.
- ``hotplug.start`` loads the hotplugging daemon, which runs all the time and
  updates the ``/dev`` hierarchy whenever the peripherals change.

The func Module
~~~~~~~~~~~~~~~

The ``func`` module contains functions which are useful for doing
higher-order programming.

- ``func.foreach(func, table)`` runs a function of the form 
  ``function(key, value)`` over each key of the table. This function always
  returns ``nil``.
- ``func.map(func, table)`` runs a function of the form 
  ``function(key, value)`` over each key-value pair in the table. Note that
  the given function can be of the form ``new_value = func(key, value)`` or
  ``new_key, new_value = func(key, value)``.
- ``func.filter(func, table)`` runs the function over each key of the table
  (of the same form accepted by ``func.foreach`` and ``func.map``), and
  adds the value to the return table under the same key if the callback
  returns ``true``.
- ``func.chain(argl, ...)`` calls all the functions in ``...`` with the
  argument list given by ``argl``.

The events Module
~~~~~~~~~~~~~~~~~

The ``events`` module is designed to abstract away the issues with the 
``os.pullEvent`` API, and instead provide a simpler callback API.

- ``events.EventLoop()`` returns an ``EventLoop`` object.

The ``EventLoop`` object has the following API:

- ``EventLoop:register(event_type, function)`` registers the given event with
  the given callback. Only one function may be registered to each callback in
  a given event loop.
- ``EventLoop:next()`` waits for the next event.
- ``EventLoop:run()`` runs the event loop until terminated.
- ``EventLoop:terminate()`` terminates the event loop.

The socket Module
~~~~~~~~~~~~~~~~~

The ``socket`` module is an abstraction on top of the networking system, which
is intended to be similar to Berkeley sockets. Currently, it does only 
connectionless datagram sockets.

- ``socket.Datagram(dev)`` returns a ``Datagram`` object, given the path to a 
  modem device.
- ``socket.generate_id()`` is not intended for public use. It generates a
  "unique" (meaning, most likely unique) token for saving a message.
- ``socket.get_last_message(token)`` takes a token given to a callback invoked
  by ``Datagram:hook_recvfrom``, and returns the ``host, port, data`` of the
  datagram's previous message (i.e. the one that caused the event to be
  invoked).

The ``Datagram`` object has the following API:

- ``Datagram:bind(port)`` readies the socket to receive messages on the given
  port. Note that multiple ports can be bound, if you want to listen for
  messages from multiple sources.
- ``Datagram:sendto(host, port, message)`` sends the given datagram to the
  given host and port. Note that, in the case of a broadcast message, the
  host should be given as ``nil`` - otherwise, it should be the ID of the
  intended receiver.
- ``Datagram:recvfrom()`` waits for a message, returning ``host, port,   
  message``. ``Datagram:recvfrom(host)`` waits for a message from a given host
  (but on any port) and ``Datagram:recvfrom(host, port)`` waits for a message
  from the given host on the given port.
- ``Datagram:hook_recvfrom(handler, host, port)`` works like 
  ``Datagram:recvfrom``, but instead of returning when the socket gets a
  message, this invokes an OS event (which can be listened to using an
  ``events.EventLoop``) called *datagram_recv* with a single parameter,
  which is a token. To access the most recently received message, access
  ``socket.get_last_message(token)`` which will return ``host, port, data`` of 
  the most recent message.
- ``Datagram:close()`` unbinds *all* ports bound by this socket.

The naming Module
~~~~~~~~~~~~~~~~~

The ``naming`` module provides a peer-to-peer host naming service.
It is intended to be resistant to network outages, by automatically starting
up whenever a modem is connected.

- ``naming:start()`` is not intended to be used by users, and exists only to
  be run by the early stages of the operating system.
- ``naming.resolve(host)`` resolves a hostname. If the host is numeric, then
  the numeric form is returned (since it is assumed to be a computer ID). If
  the hostname is registered, then the ID for the registered host is returned;
  if none is registered, then ``nil`` is returned.
- ``naming.get_hostname()`` returns the current hostname, or ``nil`` if none
  is set.
- ``naming.get_bindings()`` returns an ``host, id`` iterator for all registered
  hosts.

The deque Module
~~~~~~~~~~~~~~~~

The ``deque`` module provides an implementation of double-ended queues.

- ``deque:Deque`` returns a new ``Deque`` object.
- ``deque:fromiter(iter)`` returns a new ``Deque`` populated by the iterator.

A ``Deque`` object has the following API:

- ``Deque:tolist()`` converts the items in the deque, from left to right, into
  a list indexed at 1.
- ``Deque:len()`` returns the length of the deque.
- ``Deque:iterleft()`` and ``Deque:iterright()`` return iterators for all the
  elements in the deque - ``iterleft()`` starts from the left and goes right,
  while ``iterright()`` starts at the right and goes left.
- ``Deque:empty()`` returns ``Deque:len() == 0``.
- ``Deque:pushleft(x)`` and ``Deque:pushright(x)`` add elements to the deque,
  where the side to which the item is added should be obvious.
- ``Deque:popleft()`` and ``Deque:popright()`` remove and return the last
  element of the queue on the given side, or raise an error if the queue is
  empty.

The readline Module
~~~~~~~~~~~~~~~~~~~

The ``readline`` module provides a simple interface for line editing, which
provides basic movement and insertion features as well as history.

- ``readline.readline(prompt, [history])`` reads a line of text, using 
  ``prompt`` to delimit each screen line. If ``history`` is given, it must
  be a ``deque.Deque``, and this function will use it to provide history
  navigation. This returns the line of text read from the user.

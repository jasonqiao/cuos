Computercraft Unified Operating System
======================================

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

- ``cuos.execute(func, ...)`` schedules a particular function to be run.
  This is meant to allow the operating system to run its own processes, such
  as responding to ping requests and other things. This waits on the given
  function, returning when the function which was added to the queue stops
  running. This is intended for user programs.
- ``cuos.daemon(func, ...)`` schedules a particular function to be run.
  This is the same as ``cuos.execute``, but it runs asynchronously, allowing
  for the creation of background services.
- ``cuos.run_script(filename)`` runs a shell script, a sequence of commands
  which would otherwise be entered into the shell interactively.
- ``cuos.import(library)`` loads a module from the directory `/lib`.
  Users may put their libraries here, as CUOS tries to use the importing
  mechanism as little as possible (preferring execfiles instead).
- ``cuos.deport(library)`` does the opposite of ``cuos.import(library)``.
- ``cuos.dev(filename)`` opens up the given execfile, and returns its
  contents (or ``nil`` if the file doesn't exist).
- ``cuos.shell()`` executes a shell which is similar to the CraftOS shell.

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

The queue Module
~~~~~~~~~~~~~~~~

The ``queue`` module is an implementation of a Lua queue, using the
two-indicies method.

- ``queue.Queue()`` returns a ``Queue`` object.

The ``Queue`` object has the following API:

- ``Queue:is_empty()``
- ``Queue:push_left(value)``
- ``Queue:push_right(value)``
- ``Queue:pop_left()``
- ``Queue:pop_right()``

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
        type = "modem",
        methods = ...
    }

/dev
~~~~

``/dev`` contains a list of execfiles:

- ``/dev/net`` can be used to do socket-based networking.
- ``/dev/peripherals`` can contain the files *left*, *right*, 
    *front*, *back*, *top* and *bottom* describing the hardware devices
    connected to the machine.

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
  ``function(key, value)`` over each key of the table, putting the return
  value back into the return table under the same key.
- ``func.filter(func, table)`` runs the function over each key of the table
  (of the same form accepted by ``func.foreach`` and ``func.map``), and
  adds the value to the return table under the same key if the callback
  returns ``true``.
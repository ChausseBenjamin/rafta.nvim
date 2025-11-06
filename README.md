# Modules hierarchy

IDEA: To ease offline recovery: The bridge could be called by a cronjob with a
      cli flag. In which case it sends cached/queued updates to the server.
      Otherwise, tasks would only get synced when the rafta neovim plugin gets
      called. This would minimize risks of version conflicts

## The lua plugin

.rafta
├── bootstrap: Ensures the golang bridge is installed via `go get` or releases
│              as a last resort
├─┬ util
│ ├── cfg: Holds the global opts table before each part gets sent to the correct
│ │        module.
│ ╰── log: Logs to file and provides function to also read the log.
├─┬ model
│ ├── external: Communicates with the golang grpc-bridge and ensured the bridge
│ │             is spun up lazily to minimize startup time.
│ ╰── state: Can only be overwritten by the golang grpc-bridge.
│            The idea is that the controller diffs his buffers with this
│            immutable state to generate a queue of tasks that get sent to the
│            bridge.
├─┬ ctrl
│ ├── cmds: lua functions callable by the user
│ ╰── triggers: sets up autocommands that respond
╰─┬ view
  ├─┬ buffer: configures buffer filetypes and other
  │ ├── tasks: Main buffer that contains tasks
  │ ╰── tags: Floating buffer for editing tags
  ╰── ui: highlightGroups, icons, syntax, conceal


### Normal mode bindings

All keybindings don't have default values to avoid conflicts with other plugins
and user mappings.

- Open the description in a new temporary buffer with ft=markdown
-

## The Bridge

It is started by the lua plugin and fetches tasks from the server.
When offline, it attempts to retrieve an `encoding/gob` from a file.
When online, it stores the data it receives from the server into a cache file.

If the lua plugin asks it to perform certain actions like
creating/editing/deleting tasks, those are stored in a queue which are stored
in a separate `gob` so the updates can be pushed to the server at a later date.

Since this task management is used on a pre-user basis, collisions are
considered to be unlikely. Therefore, the latest `modified` date is picked
during conflict resollution when reconnecting.

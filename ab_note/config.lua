Config = {}

-- Chat command used to open the notebook
Config.Command = 'note'
Config.CommandDescription = 'Open your personal notebook'

-- Optional keybind (in addition to the command). Set enabled = false to disable.
Config.Keybind = {
    enabled = true,
    key = 'F6',
    description = 'Open Notebook'
}

-- Input limits (also enforced server-side, never trust the client)
Config.MaxTitleLength = 40
Config.MaxContentLength = 2000

-- Maximum notes per player. Set to 0 for unlimited.
Config.MaxNotes = 30

-- Whether to spawn the notepad/pencil prop + play the writing animation
-- while the notebook UI is open.
Config.UseProp = true

-- Disallow opening the notebook while the player is in a vehicle
Config.BlockInVehicle = true

# ab_notes

This script for the FiveM QBCore framework allows players to write and save personal notes (free-form text—such as reminders, in-game phone numbers, or RP case details). These notes are linked to the player's account (`citizenid`) and stored in the database, ensuring they persist even after a server restart.

Replacing the previous text-based menu (which relied on the `ox_lib` context menu and input dialog), the script now features a custom Graphical User Interface (NUI) designed to look like a real notebook. It retains the original "pulling out the notebook and pencil" action and animation sequence.

**Step-by-Step Workflow**
The player types `/note` or presses the F6 key (configurable).
`client.lua`:
Checks that the player is not inside a vehicle (this check can be disabled in the settings).
Spawns the `prop_notepad_01` and `prop_pencil_01` props, attaches them to the player's hands (specific bones), and plays the `missheistdockssetup1clipboard@base` animation.
Requests the player's list of notes from the server via a callback.
Opens the interface (`SetNuiFocus(true, true)`) and sends the data to it (`SendNUIMessage`).
The interface (HTML/CSS/JS) displays:
A sidebar listing all notes (title, last modified date, and a content snippet).
An editor on the right containing a title field and a content field (textarea), along with a character counter.
A "+ New" button to start a new note.
A "Save" button (also triggered by Ctrl+S).
A "Delete" button that appears only when viewing an existing note, prompting a confirmation dialog before actual deletion (replacing `lib.alertDialog`).
A close button (×) or the Esc key to close the notebook. Any interface action (save/delete/close) is sent via `fetch()` to the NUI callback in `client.lua`.
`client.lua` forwards the request to `server.lua` using a QBCore callback (`QBCore.Functions.CreateCallback`).
`server.lua` verifies the player's identity, sanitizes and trims the input (title/content)—regardless of what the client sent—executes the MySQL query (via `oxmysql`), and returns a result (`{success, message, id}`) to the interface, allowing it to update immediately without reloading the entire list.
Upon closing, the prop is removed and the animation stops.

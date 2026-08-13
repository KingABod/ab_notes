local QBCore = exports['qb-core']:GetCoreObject()

local function sanitize(str, maxLen)
    str = tostring(str or '')
    str = str:gsub('^%s+', ''):gsub('%s+$', '')
    if #str > maxLen then
        str = string.sub(str, 1, maxLen)
    end
    return str
end

QBCore.Functions.CreateCallback('ab_note:server:getNotesList', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb({}) return end

    local notes = MySQL.query.await([[
        SELECT id, title, content, DATE_FORMAT(updated_at, "%Y-%m-%d %H:%i") as updated_at
        FROM player_notes
        WHERE citizenid = ?
        ORDER BY updated_at DESC
    ]], {
        Player.PlayerData.citizenid
    })

    cb(notes or {})
end)

QBCore.Functions.CreateCallback('ab_note:server:saveNote', function(source, cb, noteId, title, content)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({ success = false, message = 'Player not found' })
        return
    end

    title = sanitize(title, Config.MaxTitleLength)
    content = sanitize(content, Config.MaxContentLength)

    if title == '' or content == '' then
        cb({ success = false, message = 'Title and content are required' })
        return
    end

    local citizenid = Player.PlayerData.citizenid

    -- Editing an existing note
    if noteId then
        -- numeric id sanity check
        noteId = tonumber(noteId)
        if not noteId then
            cb({ success = false, message = 'Invalid note' })
            return
        end

        local affectedRows = MySQL.update.await('UPDATE player_notes SET title = ?, content = ? WHERE id = ? AND citizenid = ?', {
            title, content, noteId, citizenid
        })

        if affectedRows and affectedRows > 0 then
            cb({ success = true, message = 'Note updated', id = noteId, title = title, content = content })
        else
            cb({ success = false, message = 'Unable to update note' })
        end
        return
    end

    -- Creating a new note
    if Config.MaxNotes and Config.MaxNotes > 0 then
        local count = MySQL.scalar.await('SELECT COUNT(*) FROM player_notes WHERE citizenid = ?', { citizenid })
        if count and count >= Config.MaxNotes then
            cb({ success = false, message = ('You can only have %d notes'):format(Config.MaxNotes) })
            return
        end
    end

    local id = MySQL.insert.await('INSERT INTO player_notes (citizenid, title, content) VALUES (?, ?, ?)', {
        citizenid, title, content
    })

    if id then
        cb({ success = true, message = 'Note created', id = id, title = title, content = content })
    else
        cb({ success = false, message = 'Unable to create note' })
    end
end)

QBCore.Functions.CreateCallback('ab_note:server:deleteNote', function(source, cb, noteId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({ success = false, message = 'Player not found' })
        return
    end

    noteId = tonumber(noteId)
    if not noteId then
        cb({ success = false, message = 'Invalid note' })
        return
    end

    local affectedRows = MySQL.update.await('DELETE FROM player_notes WHERE id = ? AND citizenid = ?', {
        noteId, Player.PlayerData.citizenid
    })

    if affectedRows and affectedRows > 0 then
        cb({ success = true, message = 'Note deleted', id = noteId })
    else
        cb({ success = false, message = 'Unable to delete note' })
    end
end)

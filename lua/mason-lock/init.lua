local registry = require "mason-registry"

local M = {}
M.lockfile_path = vim.fn.stdpath("config") .. "/mason-lock.json" -- TODO: Configurable

function M.read_file(file)
    local fd = assert(io.open(file, "r"))
    local data = fd:read("*a")
    fd:close()
    return data
end

function M.write_file(file, contents)
    local fd = assert(io.open(file, "w+"))
    fd:write(contents)
    fd:close()
end

function M.create_lockfile()
    local packages = registry.get_installed_packages()
    local lock_data = {}

    local callbacks_done = {}
    for _, package in pairs(packages) do
        package:get_installed_version(function(success, version)
            if not success then
                table.insert(callbacks_done, 1)
                return
            end

            lock_data[package.name] = version
            table.insert(callbacks_done, 1)
        end)
    end

    vim.wait(5000, function()
        return #packages == #callbacks_done
    end)

    M.write_file(M.lockfile_path, vim.json.encode(lock_data))
end

function M.update_lockfile(package, shouldRemove)
    local lock_data = {}
    local ok, lockfile_str = pcall(M.read_file, M.lockfile_path)
    if ok then
        lock_data = vim.json.decode(lockfile_str)
    end

    if shouldRemove then
        lock_data[package.name] = nil
        M.write_file(M.lockfile_path, vim.json.encode(lock_data))
        return
    end

    package:get_installed_version(function(success, version)
        if not success then
            return
        end
        lock_data[package.name] = version
        M.write_file(M.lockfile_path, vim.json.encode(lock_data))
    end)
end

function M.restore_from_lockfile()
    local lock_data = {}
    local ok, lockfile_str = pcall(M.read_file, M.lockfile_path)
    if not ok then
        print("No lockfile")
        return
    end

    lock_data = vim.json.decode(lockfile_str)

    local ui = require "mason.ui"
    ui.open()

    for package_name, package_version in pairs(lock_data) do
        local pkg = registry.get_package(package_name)
        pkg:install {
            version = package_version
        }
    end
end

function M.add_commands()
    vim.api.nvim_create_user_command("MasonLock", function() M.create_lockfile() end, {
        desc = "Update MasonLock lockfile",
    })

    vim.api.nvim_create_user_command("MasonLockRestore", function() M.restore_from_lockfile() end, {
        desc = "Install Mason package versions from lockfile"
    })
end

function M.add_event_listeners()
    registry:on(
        "package:install:success",
        vim.schedule_wrap(function(pkg, handle)
            M.update_lockfile(pkg)
        end)
    )

    registry:on(
        "package:uninstall:success",
        vim.schedule_wrap(function(pkg, handle)
            M.update_lockfile(pkg, true)
        end)
    )
end

function M.setup()
    M.add_commands()
    M.add_event_listeners()
end

return M

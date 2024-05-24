local registry = require "mason-registry"

local M = {}
M.lockfile_path = vim.fn.stdpath("config") .. "/mason-lock.json"
M._restore_in_progress = false

function M.read_file(file)
    local fd = assert(io.open(file, "r"))
    local data = fd:read("*a")
    fd:close()
    return data
end

function M.write_lockfile()
    if M._restore_in_progress then
        return
    end

    local packages = registry.get_installed_packages()

    local entries = {}
    for _, package in pairs(packages) do
        package:get_installed_version(function(success, version)
            if not success then
                table.insert(entries, nil)
                return
            end

            table.insert(entries, {
                name = package.name,
                version = version,
            })
        end)
    end

    vim.wait(5000, function() return #packages == #entries end)

    -- remove anything that failed
    for i, package in pairs(entries) do
        if package == nil then
            entries[i] = nil
        end
    end

    -- sort alphabetically
    table.sort(entries, function(a, b)
        return a.name:lower() < b.name:lower()
    end)

    local f = assert(io.open(M.lockfile_path, "wb"))
    f:write("{\n")

    for i, package in pairs(entries) do
        f:write(([[  %q: %q]]):format(package.name, package.version))
        if i ~= #packages then
            f:write(",\n")
        end
    end

    f:write("\n}")
    f:close()
    vim.notify("[mason-lock]: Wrote Mason lockfile")
end

function M.restore_from_lockfile()
    local lock_data = {}
    local ok, lockfile_str = pcall(M.read_file, M.lockfile_path)
    if not ok then
        vim.notify("[mason-lock]: Mason lockfile does not exist", vim.log.levels.ERROR)
        return
    end

    lock_data = vim.json.decode(lockfile_str)

    M._restore_in_progress = true

    local ui = require "mason.ui"
    ui.open()

    local huh = {}
    local finished_handles = {}

    for package_name, package_version in pairs(lock_data) do
        table.insert(huh, package_name)
        local pkg = registry.get_package(package_name)
        local handle = pkg:install {
            version = package_version
        }

        handle:once("closed", function()
            table.insert(finished_handles, package_name)
        end)
    end

    local happy, status = vim.wait(1000 * 60, function() return #finished_handles == #huh end, 300)
    if not happy then
        if status == -1 then
            vim.notify("[mason-lock]: Timedout waiting for Mason package install", vim.log.levels.ERROR)
        elseif status == -2 then
            vim.notify("[mason-lock]: Wait on Mason package install was interrupted", vim.log.levels.ERROR)
        end
    end

    M._restore_in_progress = false
    vim.notify("[mason-lock]: Restored Mason package versions from lockfile")
end

function M.add_commands()
    vim.api.nvim_create_user_command("MasonLock", function() M.write_lockfile() end, {
        desc = "Write current package versions to the Mason lockfile",
    })

    vim.api.nvim_create_user_command("MasonLockRestore", function() M.restore_from_lockfile() end, {
        desc = "Re-install Mason packages with the version specified in the lockfile"
    })
end

function M.add_event_listeners()
    registry:on(
        "package:install:success",
        vim.schedule_wrap(function(pkg, handle)
            M.write_lockfile()
        end)
    )

    registry:on(
        "package:uninstall:success",
        vim.schedule_wrap(function(pkg, handle)
            M.write_lockfile()
        end)
    )
end

function M.setup(cfg)
    if cfg and cfg.lockfile_path then
        M.lockfile_path = cfg.lockfile_path
    end

    M.add_commands()
    M.add_event_listeners()
end

return M

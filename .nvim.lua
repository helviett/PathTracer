local build_config = {
  configuration = 'debug',
}

function Build()
  vim.cmd("OpenTerminal")
  local tid = vim.b.terminal_job_id
  if tid then
    vim.cmd("norm G")
    local bc = build_config
    local cmd = "jai first.jai -output_path build/"
    vim.fn.chansend(
      tid,
      cmd .. "\r\n"
    )
  end
end

function Run()
  vim.cmd("OpenTerminal")
  local tid = vim.b.terminal_job_id
  if tid then
    vim.cmd("norm G")
    local cmd = "raddbg.exe --ipc launch_and_run"
    vim.fn.chansend(
      tid,
      cmd .. "\r\n"
    )
  end
end

function BuildAndRun()
  vim.cmd("OpenTerminal")
  local tid = vim.b.terminal_job_id
  if tid then
    vim.cmd("norm G")
    local bc = build_config
    local build_cmd = "jai first.jai -output_path build/"
    local run_cmd = "raddbg.exe --ipc launch_and_run"
    vim.fn.chansend(
      tid,
      build_cmd .. " && " .. run_cmd .. "\r\n"
    )
  end
end


vim.api.nvim_set_keymap("n", "<leader>pb", ":lua Build()<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>pr", ":lua BuildAndRun()<CR>", { noremap = true })
-- vim.api.nvim_set_keymap("n", "<leader>pbr", ":lua BuildAndRun()<CR>", { noremap = true })

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>fj', function() builtin.find_files({cwd = 'D:\\projects\\jai'}) end, { desc = 'Jai Find Files' })
vim.keymap.set('n', '<leader>rj', function() builtin.live_grep({cwd = 'D:\\projects\\jai'}) end, { desc = 'Jai Grep Files' })

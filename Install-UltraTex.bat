@echo off
setlocal
title PixelArtistry - UltraTex Installer
chcp 65001 >nul

rem ==========================================================================
rem  UltraTex one-click installer for ComfyUI (Windows, portable / Easy-Install)
rem  by PixelArtistry - free on github.com/pixelartistry
rem
rem  Nodes:  visualbruno/ComfyUI-UltraTex (MIT), pinned to the tested commit
rem  Model:  FLUX.2 Klein BASE 9B fp8 (FLUX Non-Commercial License, gated on HF)
rem
rem  Works from any of these places - just double-click it there:
rem    - ComfyUI-Easy-Install\Add-Ons\UltraTex-PixelArtistry\   (the unzipped release)
rem    - ComfyUI-Easy-Install\Add-Ons\        (as an Easy-Install add-on)
rem    - the folder that contains "python_embeded" and "ComfyUI"
rem    - the ComfyUI folder itself
rem  Close ComfyUI first. Safe to re-run: existing files are skipped,
rem  unfinished downloads resume. Pass NoPause to skip the final pause.
rem ==========================================================================

set "COMMIT=8137da52ed8352305cb7825b39c36a250bf2507a"
set "NODE_REPO=https://github.com/visualbruno/ComfyUI-UltraTex"
set "RGTHREE_REPO=https://github.com/rgthree/rgthree-comfy"
rem Low-VRAM (GGUF) version: MostAadTech's node pack, pinned to the tested commit
set "MAD_COMMIT=b98f4f45057a5a40561ffbb0770ef3a4e0400112"
set "MAD_REPO=https://github.com/Mstafa-awad/UltraTex-ComfyUI-nodes"
set "GGUF_REPO=https://github.com/city96/ComfyUI-GGUF"
set "URL_KQ4=https://huggingface.co/unsloth/FLUX.2-klein-base-9B-GGUF/resolve/main/flux-2-klein-base-9b-Q4_0.gguf"
set "URL_QWENQ4=https://huggingface.co/unsloth/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf"

set "URL_KLEIN=https://huggingface.co/black-forest-labs/FLUX.2-klein-base-9b-fp8/resolve/main/flux-2-klein-base-9b-fp8.safetensors"
set "URL_QWEN=https://huggingface.co/Comfy-Org/flux2-klein-9B/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors"
set "URL_VAE=https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors"
set "URL_BIREF=https://huggingface.co/Comfy-Org/BiRefNet/resolve/main/background_removal/birefnet.safetensors"
set "KLEIN_PAGE=https://huggingface.co/black-forest-labs/FLUX.2-klein-base-9b-fp8"

echo.
echo  ============================================================
echo    UltraTex for ComfyUI - one-click installer by PixelArtistry
echo  ============================================================
echo.

rem ---------------------------------------------------------------- 1. find ComfyUI
set "ROOT="
if exist "%~dp0python_embeded\python.exe" if exist "%~dp0ComfyUI\main.py" set "ROOT=%~dp0."
if not defined ROOT if exist "%~dp0..\python_embeded\python.exe" if exist "%~dp0..\ComfyUI\main.py" set "ROOT=%~dp0.."
if not defined ROOT if exist "%~dp0..\python_embeded\python.exe" if exist "%~dp0main.py" set "ROOT=%~dp0.."
rem The unzipped release folder inside Add-Ons: Add-Ons\UltraTex-PixelArtistry\Install-UltraTex.bat
if not defined ROOT if exist "%~dp0..\..\python_embeded\python.exe" if exist "%~dp0..\..\ComfyUI\main.py" set "ROOT=%~dp0..\.."
if not defined ROOT (
    echo  [ERROR] Could not find "python_embeded" and "ComfyUI" next to this file.
    echo          Put Install-UltraTex.bat into ComfyUI-Easy-Install\Add-Ons, or into the
    echo          folder that contains python_embeded, and run it again.
    goto :fail
)
for %%I in ("%ROOT%") do set "ROOT=%%~fI"
set "PY=%ROOT%\python_embeded\python.exe"
set "COMFY=%ROOT%\ComfyUI"
set "CN=%COMFY%\custom_nodes"
set "MODELS=%COMFY%\models"
set "NODE_DIR=%CN%\ComfyUI-UltraTex"
set "WARN=%TEMP%\ultratex_install_warnings.txt"
if exist "%WARN%" del "%WARN%"

echo  ComfyUI found: %COMFY%

rem pip must not run while ComfyUI has the packages loaded.
rem Port: the --port value in "Start ComfyUI.bat" (Easy-Install root), else 8188.
set "PORT="
if exist "%TEMP%\utx_port.txt" del "%TEMP%\utx_port.txt"
if exist "%ROOT%\Start ComfyUI.bat" "%PY%" -I -c "import sys,re;t=open(sys.argv[1],errors='ignore').read();m=re.findall(r'^(?!\s*(?:rem|::)).*?--port[= ]+(\d+)',t,re.M|re.I);print(m[-1] if m else '')" "%ROOT%\Start ComfyUI.bat" > "%TEMP%\utx_port.txt" 2>nul
if exist "%TEMP%\utx_port.txt" set /p PORT=<"%TEMP%\utx_port.txt"
if not defined PORT set "PORT=8188"
netstat -ano | findstr /r /c:":%PORT% .*LISTENING" >nul 2>&1
if not errorlevel 1 (
    echo.
    echo  [ERROR] ComfyUI seems to be running on port %PORT%. Close it first, then run this again.
    goto :fail
)

"%PY%" -c "import torch;v=torch.__version__.split('+')[0].split('.');print(v[0]+'.'+v[1])" > "%TEMP%\utx_torch.txt" 2>nul
set "TV="
set /p TV=<"%TEMP%\utx_torch.txt"
if not defined TV (
    echo  [ERROR] PyTorch is not working in python_embeded. Fix your ComfyUI install first.
    goto :fail
)
echo  PyTorch:       %TV%
echo.

rem ---------------------------------------------------------------- 2. ComfyUI version check
echo  [1/7] Checking ComfyUI version...
if exist "%COMFY%\comfy_extras\nodes_mesh_postprocess.py" (
    echo        OK - GPU UV unwrap available ^(comfy_gpu, seconds instead of minutes^).
) else (
    echo        WARNING - your ComfyUI is too old for the GPU UV unwrap.
    >>"%WARN%" echo  - ComfyUI is outdated: UV unwrap falls back to xatlas ^(CPU, minutes^). Update ComfyUI.
)

rem ---------------------------------------------------------------- 3. nodes
echo.
echo  [2/7] Installing ComfyUI-UltraTex nodes ^(commit %COMMIT:~0,7%^)...
where git >nul 2>&1
if errorlevel 1 goto :nodes_zip

if exist "%NODE_DIR%\.git" (
    git -C "%NODE_DIR%" fetch --quiet origin
) else (
    if exist "%NODE_DIR%" rmdir /s /q "%NODE_DIR%"
    git clone --quiet "%NODE_REPO%" "%NODE_DIR%"
)
git -C "%NODE_DIR%" checkout --quiet %COMMIT%
if errorlevel 1 (
    echo  [ERROR] git could not check out the tested commit.
    goto :fail
)
goto :nodes_done

:nodes_zip
echo        git not found - downloading the pinned version as a zip instead.
if exist "%NODE_DIR%" rmdir /s /q "%NODE_DIR%"
curl -L --fail -s -o "%TEMP%\utx_nodes.zip" "https://codeload.github.com/visualbruno/ComfyUI-UltraTex/zip/%COMMIT%"
if errorlevel 1 (
    echo  [ERROR] Download of the nodes failed. Check your internet connection.
    goto :fail
)
if exist "%TEMP%\utx_nodes" rmdir /s /q "%TEMP%\utx_nodes"
mkdir "%TEMP%\utx_nodes"
tar -xf "%TEMP%\utx_nodes.zip" -C "%TEMP%\utx_nodes"
move "%TEMP%\utx_nodes\ComfyUI-UltraTex-%COMMIT%" "%NODE_DIR%" >nul
if not exist "%NODE_DIR%\nodes.py" (
    echo  [ERROR] Could not unpack the nodes.
    goto :fail
)

:nodes_done
echo        OK - %NODE_DIR%

rem rgthree is needed by the advanced 10-view workflow (Fast Groups Bypasser)
if exist "%CN%\rgthree-comfy" (
    echo        rgthree-comfy already installed.
) else (
    echo        Installing rgthree-comfy ^(used by the 10-view workflow^)...
    call :install_rgthree
)

rem ---------------------------------------------------------------- low VRAM option
echo.
echo        Optional: low-VRAM version for 6-8 GB GPUs ^(GGUF, nodes by MostAadTech^).
echo        Adds the node pack, ComfyUI-GGUF and two GGUF models ^(about 11 GB^).
set "LOWVRAM="
set "MAD_DIR=%CN%\comfyui_ultratex_modular"
rem Reuse an existing copy under its repo name: two active copies of this pack conflict.
if exist "%CN%\UltraTex-ComfyUI-nodes\__init__.py" set "MAD_DIR=%CN%\UltraTex-ComfyUI-nodes"
if exist "%MAD_DIR%\__init__.py" (
    echo        Low-VRAM node pack already installed - updating it to the tested version.
    set "LOWVRAM=1"
    goto :lowvram_install
)
if /i "%~1"=="NoPause" (
    set "LOWVRAM=1"
    goto :lowvram_install
)
choice /c YN /n /m "        Install the low-VRAM version too? [Y/N] "
if errorlevel 2 goto :lowvram_done
set "LOWVRAM=1"

:lowvram_install
call :git_node "%MAD_REPO%" "%MAD_DIR%" "%MAD_COMMIT%" "UltraTex-ComfyUI-nodes-%MAD_COMMIT%" "https://codeload.github.com/Mstafa-awad/UltraTex-ComfyUI-nodes/zip/%MAD_COMMIT%"
if errorlevel 1 (
    >>"%WARN%" echo  - Low-VRAM node pack ^(MostAadTech^) could not be installed.
    set "LOWVRAM="
    goto :lowvram_done
)
echo        OK - MostAadTech UltraTex nodes ^(commit %MAD_COMMIT:~0,7%^)
if exist "%CN%\ComfyUI-GGUF\__init__.py" (
    echo        ComfyUI-GGUF already installed.
) else (
    call :git_node "%GGUF_REPO%" "%CN%\ComfyUI-GGUF" "" "ComfyUI-GGUF-main" "https://codeload.github.com/city96/ComfyUI-GGUF/zip/refs/heads/main"
    if errorlevel 1 >>"%WARN%" echo  - ComfyUI-GGUF could not be installed: install it via ComfyUI Manager.
)
:lowvram_done

rem ---------------------------------------------------------------- 4. python packages
echo.
echo  [3/7] Installing Python packages ^(trimesh, moderngl, xatlas, scipy, modelscope^)...
"%PY%" -I -m pip install --quiet --disable-pip-version-check --no-warn-script-location -r "%NODE_DIR%\requirements.txt" modelscope
if errorlevel 1 (
    echo  [ERROR] pip install failed. Scroll up for the error.
    goto :fail
)
if not defined LOWVRAM goto :pip_done
echo        Low-VRAM packages ^(einops, glcontext, psutil, gguf^)...
"%PY%" -I -m pip install --quiet --disable-pip-version-check --no-warn-script-location -r "%MAD_DIR%\requirements.txt" "gguf>=0.13"
if errorlevel 1 >>"%WARN%" echo  - pip install for the low-VRAM pack failed. Scroll up for the error.
:pip_done
echo        OK

rem ---------------------------------------------------------------- 5. triton
echo.
echo  [4/7] Triton ^(speed boost for the sparse attention^)...
"%PY%" -c "import triton" >nul 2>&1
if not errorlevel 1 (
    echo        Triton already installed - keeping your version.
    goto :triton_test
)
set "TRI="
if "%TV%"=="2.6" set "TRI=triton-windows<3.3"
if "%TV%"=="2.7" set "TRI=triton-windows<3.4"
if "%TV%"=="2.8" set "TRI=triton-windows<3.5"
if "%TV%"=="2.9" set "TRI=triton-windows<3.6"
if "%TV%"=="2.10" set "TRI=triton-windows<3.7"
if "%TV%"=="2.11" set "TRI=triton-windows<3.7"
if "%TV%"=="2.12" set "TRI=triton-windows<3.8"
if "%TV%"=="2.13" set "TRI=triton-windows<3.8"
if not defined TRI (
    echo        No known Triton match for PyTorch %TV% - skipping. UltraTex still works, just slower.
    >>"%WARN%" echo  - Triton skipped ^(PyTorch %TV%^): sampler uses ComfyUI attention, slower at 2048.
    goto :triton_done
)
echo        Installing "%TRI%" for PyTorch %TV%...
"%PY%" -I -m pip install --quiet --disable-pip-version-check "%TRI%"

:triton_test
rem Runs the exact Triton kernel UltraTex uses, on the GPU, once.
"%PY%" -c "import sys;sys.path.insert(0,r'%NODE_DIR%');from ultratex_core.optim import check_sparse_attention as c;e=c();print('OK' if e is None else 'FAIL '+e)" > "%TEMP%\utx_tri.txt" 2>nul
findstr /x "OK" "%TEMP%\utx_tri.txt" >nul 2>&1
if not errorlevel 1 (
    echo        OK - sparse attention kernel runs on your GPU.
) else (
    echo        WARNING - Triton test failed:
    type "%TEMP%\utx_tri.txt"
    echo        UltraTex still works, it falls back to ComfyUI attention ^(slower^).
    >>"%WARN%" echo  - Triton kernel test failed: sampler falls back to ComfyUI attention.
)
:triton_done

rem ---------------------------------------------------------------- 6. models
echo.
echo  [5/7] Models - checking ComfyUI\models and extra_model_paths.yaml...
rem The scan uses ComfyUI's own folder logic (python block at the end of this file),
rem so linked folders from Easy-Models-Linker count, and new downloads go to the
rem folder ComfyUI treats as default (is_default: true) for each model type.
for %%K in (KLEIN QWEN VAE LORA LORAMR DEC BIREF KQ4 QWENQ4 NEED) do (
    set "S_%%K="
    set "T_%%K="
)
if exist "%TEMP%\utx_models.txt" del "%TEMP%\utx_models.txt"
"%PY%" -c "import sys;exec(open(sys.argv[1],encoding='utf-8').read().split('#PYMODELS#\n',1)[1])" "%~f0" "%COMFY%" "%TEMP%\utx_models.txt" "%LOWVRAM%"
if not exist "%TEMP%\utx_models.txt" (
    echo  [ERROR] Could not check the model folders. Scroll up for the error.
    goto :fail
)
for /f "usebackq tokens=1,2,* delims=|" %%a in ("%TEMP%\utx_models.txt") do (
    set "S_%%a=%%b"
    set "T_%%a=%%c"
)
if not defined S_NEED (
    echo.
    echo        All models are already there.
    goto :workflows
)
echo.
if /i "%~1"=="NoPause" goto :do_models
choice /c YN /n /m "        Download the missing models now? [Y/N] "
if errorlevel 2 (
    echo        Skipped. Run the installer again any time to download them.
    >>"%WARN%" echo  - Models not downloaded ^(you chose N^). Re-run the installer to get them.
    goto :workflows
)
:do_models
echo.
if "%S_KLEIN%"=="MISSING" call :get_klein
if "%S_QWEN%"=="MISSING" (
    echo        Qwen3 8B text encoder ^(~8.7 GB^)...
    call :download "%URL_QWEN%" "%T_QWEN%" noauth
    if errorlevel 1 >>"%WARN%" echo  - Qwen3 8B text encoder download failed.
)
if "%S_VAE%"=="MISSING" (
    echo        FLUX.2 VAE...
    call :download "%URL_VAE%" "%T_VAE%" noauth
    if errorlevel 1 >>"%WARN%" echo  - FLUX.2 VAE download failed.
)
if "%S_BIREF%"=="MISSING" (
    echo        BiRefNet background removal...
    call :download "%URL_BIREF%" "%T_BIREF%" noauth
    if errorlevel 1 >>"%WARN%" echo  - BiRefNet download failed: the workflows need it to cut out the reference.
)
rem UltraTex files from ModelScope (renamed: both LoRAs are called dit_lora there)
call :write_ms_helper
if "%S_LORA%"=="MISSING"   call :ultratex_file "flux2/lora/dit_lora.safetensors"    "%T_LORA%"   "UltraTex albedo LoRA"
if "%S_LORAMR%"=="MISSING" call :ultratex_file "flux2_mr/lora/dit_lora.safetensors" "%T_LORAMR%" "UltraTex metallic-roughness LoRA"
if "%S_DEC%"=="MISSING"    call :ultratex_file "flux2/decoder.pt"                   "%T_DEC%"    "UltraTex foreground decoder"
if "%S_KQ4%"=="MISSING" (
    echo        Klein base 9B GGUF Q4_0 ^(~5.6 GB, low-VRAM version^)...
    call :download "%URL_KQ4%" "%T_KQ4%" noauth
    if errorlevel 1 >>"%WARN%" echo  - Klein base 9B GGUF download failed.
)
if "%S_QWENQ4%"=="MISSING" (
    echo        Qwen3 8B GGUF Q4_K_M ^(~5 GB, low-VRAM version^)...
    call :download "%URL_QWENQ4%" "%T_QWENQ4%" noauth
    if errorlevel 1 >>"%WARN%" echo  - Qwen3 8B GGUF download failed.
)

rem ---------------------------------------------------------------- 7. workflows
:workflows
echo.
echo  [6/7] Adding workflows to the ComfyUI workflow browser...
set "WF=%COMFY%\user\default\workflows"
if not exist "%WF%" mkdir "%WF%"
rem PixelArtistry workflows ship in a "workflows" folder next to this installer.
if exist "%~dp0workflows\UltraTex - 1 Standard 6 views PBR.json" (
    set "EX=%~dp0workflows"
    goto :pa_workflows
)
echo        PixelArtistry workflows not found next to the installer - adding the developer's examples.
>>"%WARN%" echo  - PixelArtistry workflows missing: unzip the whole UltraTex-PixelArtistry folder into Add-Ons and run the installer from there.
set "PA_WF="
set "EX=%NODE_DIR%\example_workflows"
call :copy_wf "UltraTex PBR Flux2Klein9B at 1024px.json" "UltraTex - Standard 6 views PBR 1024px.json"
call :copy_wf "UltraTex PBR Flux2Klein9B at 2048px.json" "UltraTex - Standard 6 views PBR 2048px.json"
call :copy_wf "UltraTex Albedo Flux2Klein9B.json"        "UltraTex - Advanced 10 views albedo.json"
goto :wf_done
:pa_workflows
set "PA_WF=1"
call :copy_wf "UltraTex - 1 Standard 6 views PBR.json"   "UltraTex - 1 Standard 6 views PBR.json"
call :copy_wf "UltraTex - 2 Advanced 10 views PBR.json"  "UltraTex - 2 Advanced 10 views PBR.json"
if defined LOWVRAM call :copy_wf "UltraTex - 3 Low VRAM GGUF.json" "UltraTex - 3 Low VRAM GGUF.json"
:wf_done

rem ---------------------------------------------------------------- summary
echo.
echo  [7/7] Done.
echo.
echo  ============================================================
if exist "%WARN%" (
    echo   Finished with warnings:
    type "%WARN%"
) else (
    echo   Everything installed.
)
echo  ============================================================
echo.
echo   Next steps:
echo   1. Restart ComfyUI.
if defined PA_WF (
    echo   2. Open a workflow from the sidebar: "UltraTex - 1 Standard 6 views PBR".
) else (
    echo   2. Open a workflow from the sidebar: "UltraTex - Standard 6 views PBR 1024px".
)
echo   3. Pick YOUR mesh in "UltraTex Load Mesh" and YOUR reference image
echo      ^(any background works, ideally the image the mesh was made from^).
echo   4. On the first run, the console should show
echo      "UltraTex LoRA ... layers patched of ..." for BOTH LoRAs.
echo.
echo   License:
echo   - UltraTex code: MIT.
echo   - FLUX.2 Klein base 9B weights: FLUX Non-Commercial License v2.1.
echo   - Your textures are yours: Black Forest Labs claims no ownership of the
echo     outputs, and the license allows using them for any purpose, including
echo     commercial - except training a model that competes with FLUX.
echo   - Running the model itself is licensed for non-commercial use. For client
echo     or production work, check https://bfl.ai/licensing first.
echo.
if /i not "%~1"=="NoPause" pause
exit /b 0

:fail
echo.
echo  Installation stopped. Nothing else was changed.
echo.
if /i not "%~1"=="NoPause" pause
exit /b 1


rem ==========================================================================
rem  Subroutines
rem ==========================================================================

:get_klein
if not defined HF_TOKEN call :ask_token
if not defined HF_TOKEN (
    echo        Skipped Klein base 9B - no token.
    >>"%WARN%" echo  - Klein base 9B fp8 NOT downloaded. Get it from %KLEIN_PAGE%
    exit /b 0
)
echo        Klein base 9B fp8 ^(~9 GB^)...
call :download "%URL_KLEIN%" "%T_KLEIN%" auth
if errorlevel 1 (
    echo        Download failed. Did you click "Agree" on the model page with the same account?
    >>"%WARN%" echo  - Klein base 9B fp8 download failed: accept the license on %KLEIN_PAGE% and check your token.
)
exit /b 0

:download
rem %1 = url, %2 = target file, %3 = auth / noauth
rem Downloads to <file>.part (resumable), renames when complete.
if not exist "%~dp2" mkdir "%~dp2"
call :curl_get "%~1" "%~2" "%~3"
if not errorlevel 1 goto :download_ok
rem A broken or already-complete .part makes resuming fail - start that file over once.
if exist "%~2.part" (
    echo        Resume failed - restarting this download from scratch...
    del "%~2.part"
    call :curl_get "%~1" "%~2" "%~3"
    if not errorlevel 1 goto :download_ok
)
echo        Download failed:
echo          from: %~1
echo          to:   %~2
exit /b 1
:download_ok
move /y "%~2.part" "%~2" >nul
if not exist "%~2" exit /b 1
echo        Saved: %~2
exit /b 0

:curl_get
if /i "%~3"=="auth" (
    curl -L --fail -C - --retry 3 -H "Authorization: Bearer %HF_TOKEN%" -o "%~2.part" "%~1"
) else (
    curl -L --fail -C - --retry 3 -o "%~2.part" "%~1"
)
exit /b %errorlevel%

:ask_token
echo.
echo        The Klein base 9B model is gated on Hugging Face. Two quick steps:
echo          a^) Open %KLEIN_PAGE%
echo             log in and click "Agree" ^(free, non-commercial license^).
echo          b^) Create a "Read" token at https://huggingface.co/settings/tokens
echo        Paste the token here and press Enter ^(or just Enter to skip^):
set /p "HF_TOKEN=       Token: "
exit /b 0

:write_ms_helper
set "MSPY=%TEMP%\utx_modelscope_dl.py"
> "%MSPY%" echo import sys, os, shutil
>>"%MSPY%" echo from modelscope.hub.file_download import model_file_download
>>"%MSPY%" echo src, dst, tmp = sys.argv[1:4]
>>"%MSPY%" echo path = None
>>"%MSPY%" echo for ep in [None, "https://www.modelscope.ai"]:
>>"%MSPY%" echo     try:
>>"%MSPY%" echo         path = model_file_download("Yibo-Zhang/UltraTex", src, local_dir=tmp, endpoint=ep)
>>"%MSPY%" echo         break
>>"%MSPY%" echo     except Exception as e:
>>"%MSPY%" echo         print("        ModelScope", ep or "default", "failed:", e)
>>"%MSPY%" echo if not path or not os.path.isfile(path): sys.exit(1)
>>"%MSPY%" echo os.makedirs(os.path.dirname(dst), exist_ok=True)
>>"%MSPY%" echo shutil.move(path, dst)
exit /b 0

:ultratex_file
rem %1 = path inside the ModelScope repo, %2 = target file, %3 = label
if exist "%~2" (
    echo        %~3 - already there, skipped.
    exit /b 0
)
echo        %~3...
"%PY%" "%MSPY%" "%~1" "%~2" "%TEMP%\utx_modelscope"
if errorlevel 1 (
    echo        Download failed.
    >>"%WARN%" echo  - %~3 download failed ^(ModelScope Yibo-Zhang/UltraTex, %~1^).
)
exit /b 0

:copy_wf
rem %1 = example file, %2 = name in the workflow browser (existing files are kept)
if not exist "%EX%\%~1" (
    >>"%WARN%" echo  - Example workflow missing: %~1
    exit /b 0
)
if exist "%WF%\%~2" (
    echo        %~2 - already there, kept your version.
) else (
    copy "%EX%\%~1" "%WF%\%~2" >nul
    echo        %~2
)
exit /b 0

:git_node
rem %1 = repo url, %2 = target folder, %3 = commit (empty = latest), %4 = top folder inside the zip, %5 = zip url
where git >nul 2>&1
if errorlevel 1 goto :git_node_zip
if exist "%~2\.git" (
    git -C "%~2" fetch --quiet origin
) else (
    if exist "%~2" rmdir /s /q "%~2"
    git clone --quiet "%~1" "%~2"
)
if errorlevel 1 exit /b 1
if not "%~3"=="" git -C "%~2" checkout --quiet %~3
if errorlevel 1 exit /b 1
exit /b 0
:git_node_zip
if exist "%~2" rmdir /s /q "%~2"
curl -L --fail -s -o "%TEMP%\utx_node.zip" "%~5"
if errorlevel 1 exit /b 1
if exist "%TEMP%\utx_node" rmdir /s /q "%TEMP%\utx_node"
mkdir "%TEMP%\utx_node"
tar -xf "%TEMP%\utx_node.zip" -C "%TEMP%\utx_node"
move "%TEMP%\utx_node\%~4" "%~2" >nul
if not exist "%~2\__init__.py" exit /b 1
exit /b 0

:install_rgthree
where git >nul 2>&1
if not errorlevel 1 (
    git clone --quiet "%RGTHREE_REPO%" "%CN%\rgthree-comfy"
    exit /b 0
)
curl -L --fail -s -o "%TEMP%\rgthree.zip" "https://codeload.github.com/rgthree/rgthree-comfy/zip/refs/heads/main"
if errorlevel 1 (
    >>"%WARN%" echo  - rgthree-comfy not installed: the 10-view workflow needs it ^(install via ComfyUI Manager^).
    exit /b 0
)
if exist "%TEMP%\rgthree" rmdir /s /q "%TEMP%\rgthree"
mkdir "%TEMP%\rgthree"
tar -xf "%TEMP%\rgthree.zip" -C "%TEMP%\rgthree"
move "%TEMP%\rgthree\rgthree-comfy-main" "%CN%\rgthree-comfy" >nul
exit /b 0

rem ==========================================================================
rem  Python: model scan (read by step 5, never run by cmd)
rem ==========================================================================
#PYMODELS#
import os, sys, logging
comfy, out = sys.argv[2], sys.argv[3]
lowvram = len(sys.argv) > 4 and sys.argv[4] == "1"
sys.path.insert(0, comfy)
os.chdir(comfy)
logging.disable(logging.CRITICAL)
import folder_paths
folder_paths.add_model_folder_path("ultratex", os.path.join(folder_paths.models_dir, "ultratex"))
if "background_removal" not in folder_paths.folder_names_and_paths:
    folder_paths.add_model_folder_path("background_removal", os.path.join(folder_paths.models_dir, "background_removal"))
yaml_path = os.path.join(comfy, "extra_model_paths.yaml")
if os.path.isfile(yaml_path):
    try:
        from utils.extra_config import load_extra_path_config
        load_extra_path_config(yaml_path)
        print("       Found extra_model_paths.yaml - linked model folders are included.")
    except Exception as e:
        print("       WARNING: could not read extra_model_paths.yaml:", e)
else:
    print("       No extra_model_paths.yaml - checking ComfyUI\\models only.")

MODELS = [
    ("KLEIN",  "flux-2-klein-base-9b-fp8.safetensors", ["diffusion_models"], "Klein base 9B fp8 (~9 GB, HF token)"),
    ("QWEN",   "qwen_3_8b_fp8mixed.safetensors",       ["text_encoders"],    "Qwen3 8B text encoder (~8.7 GB)"),
    ("VAE",    "flux2-vae.safetensors",                ["vae"],              "FLUX.2 VAE"),
    ("LORA",   "ultratex_flux2.safetensors",           ["loras"],            "UltraTex albedo LoRA"),
    ("LORAMR", "ultratex_flux2_mr.safetensors",        ["loras"],            "UltraTex MR LoRA"),
    ("DEC",    "ultratex_flux2_decoder.pt",            ["ultratex", "vae"],  "UltraTex decoder"),
    ("BIREF",  "birefnet.safetensors",                 ["background_removal"], "BiRefNet background removal"),
]
if lowvram:
    MODELS += [
        ("KQ4",    "flux-2-klein-base-9b-Q4_0.gguf",   ["diffusion_models"], "Klein base 9B GGUF Q4_0 (~5.6 GB)"),
        ("QWENQ4", "Qwen3-8B-Q4_K_M.gguf",             ["text_encoders"],    "Qwen3 8B GGUF Q4_K_M (~5 GB)"),
    ]

def find(name, kinds):
    name = name.lower()
    for kind in kinds:
        for d in folder_paths.get_folder_paths(kind):
            if not os.path.isdir(d):
                continue
            for root, _dirs, files in os.walk(d, followlinks=True):
                for f in files:
                    if f.lower() == name:
                        return os.path.join(root, f)
    return None

lines, missing = [], 0
print()
for key, name, kinds, label in MODELS:
    hit = find(name, kinds)
    if hit:
        print("       found    %-36s %s" % (label, hit))
        lines.append("%s|FOUND|%s" % (key, hit))
    else:
        # resume an unfinished download (.part) wherever it already is
        target = os.path.join(folder_paths.get_folder_paths(kinds[0])[0], name)
        for d in folder_paths.get_folder_paths(kinds[0]):
            if os.path.isfile(os.path.join(d, name + ".part")):
                target = os.path.join(d, name)
                break
        print("       MISSING  %-36s -> %s" % (label, target))
        lines.append("%s|MISSING|%s" % (key, target))
        missing += 1
if missing:
    lines.append("NEED|1|")
with open(out, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines) + "\n")

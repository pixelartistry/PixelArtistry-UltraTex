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
rem Same place as the other PixelArtistry workflows: sidebar folder "PixelArtistry".
rem The workflows are embedded at the end of this file (gzip + base64), so the
rem installer also works on its own, without the "workflows" folder next to it.
set "WF=%COMFY%\user\default\workflows\PixelArtistry"
"%PY%" -I -c "import sys;t=open(sys.argv[1],encoding='utf-8').read();exec(t.split('#'+'WORKFLOWS'+'#\n',1)[1].split('#'+'END'+'#',1)[0])" "%~f0" "%WF%" "%LOWVRAM%"
if errorlevel 1 >>"%WARN%" echo  - Could not write the PixelArtistry workflows to %WF%.
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
echo   2. Workflows sidebar, folder PixelArtistry: "PixelArtistry_UltraTex_01_Standard_6views_PBR".
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
rem  The 3 PixelArtistry workflows (gzip + base64) for step 6.
rem  cmd never runs the lines below; step 6 unpacks them with Python.
rem ==========================================================================
#WORKFLOWS#
import base64, gzip, os, sys
dest = sys.argv[2]
lowvram = len(sys.argv) > 3 and sys.argv[3] == "1"
os.makedirs(dest, exist_ok=True)
FILES = [
    ("PixelArtistry_UltraTex_01_Standard_6views_PBR.json", False, (
        "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"
    )),
    ("PixelArtistry_UltraTex_02_Advanced_10views_PBR.json", False, (
        "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"
        "KC3j3X/+H/aH5h7ZeAAA"
    )),
    ("PixelArtistry_UltraTex_03_LowVRAM_GGUF.json", True, (
        "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"
        "mddThI8AAA=="
    )),
]
for name, low, data in FILES:
    if low and not lowvram:
        continue
    path = os.path.join(dest, name)
    if os.path.exists(path):
        print("       " + name + " - already there, kept your version.")
        continue
    with open(path, 'wb') as fh:
        fh.write(gzip.decompress(base64.b64decode(data)))
    print("       " + name)
#END#

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

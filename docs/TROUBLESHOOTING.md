# Troubleshooting

Back to the [README](../README.md).

## "413 Request Entity Too Large" when loading a mesh (workflow 3)

The GLB is bigger than ComfyUI's 100 MB upload limit. Two fixes:

- **Fix A:** copy the GLB into `ComfyUI\input\3d\` and press **R** in ComfyUI. It then shows up in the Load 3D list without uploading.
- **Fix B:** add `--max-upload-size 2048` to the end of the python line in `Start ComfyUI.bat` and save. Then **fully close and reopen the Easy-Install (EZi) app**: restarting only ComfyUI keeps the old arguments. Check that the first console line (`Command: ...`) shows the flag.

## MR LoRA silently not loading

The stock **Load LoRA** node can't read UltraTex LoRAs, and it fails without an error. The workflows use **UltraTex Load LoRA** for that reason. Don't swap it.

On the first run, the console must show `UltraTex LoRA ... layers patched of N` for **both** LoRAs (albedo and metallic-roughness).

## MR preview shows a painted character instead of flat maps

The MR LoRA isn't active. The MR output should look like flat colored maps, not a painted character. Check the console line from the section above and that `ultratex_flux2_mr.safetensors` is picked in the MR loader.

## Reference check preview looks wrong

The object must fill the mesh silhouette **edge to edge**. If it's small or shifted, the mask is wrong:

- Workflows 1/2: Prep `mask_meaning` must be `foreground` with BiRefNet, or `background (LoadImage)` if you connect Load Image's own MASK instead.
- Workflow 3: Prepare `mask_polarity` must be `foreground` with BiRefNet, `background` with Load Image's MASK.

## Red UTX nodes / "UNKNOWN" widgets in workflow 3

The low-VRAM node pack isn't installed. Rerun `Install-UltraTex.bat` and answer **Y** to the low-VRAM question. It also needs [ComfyUI-GGUF](https://github.com/city96/ComfyUI-GGUF).

## Triton test failed

- **Workflows 1/2** still work: they fall back to slower attention. If a sampler errors, set `attention = comfy_default` (slower, same result).
- **Workflow 3** needs Triton. There's no fallback.

Install `triton-windows` matching your PyTorch version: [woct0rdho/triton-windows](https://github.com/woct0rdho/triton-windows).

## Downloads failed

The installer prints the source URL and the target path for every failed download. Rerun the installer: finished files are skipped and unfinished downloads resume.

For the gated Klein fp8 model: click "Agree" on the [model page](https://huggingface.co/black-forest-labs/FLUX.2-klein-base-9b-fp8) with the same account your token belongs to, and use a **Read** token.

## "PixelArtistry workflows missing" warning

The `.bat` was run without the `workflows` folder next to it, so the installer added the developer's example workflows instead. Unzip the **whole** repo folder into `Add-Ons` and run the installer from inside that folder.

## "ComfyUI seems to be running"

Close ComfyUI first: pip can't update packages while ComfyUI has them loaded. The installer checks the `--port` from `Start ComfyUI.bat` (8188 if there's none).

## Fast re-runs

ComfyUI reuses cached results when you only change later settings. Changing only the bake settings, for example, doesn't repaint the views.

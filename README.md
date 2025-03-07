### A Sawayama Solitaire clone written in Odin and Raylib

This is my first game!

Its just a clone of one of the solitaire games from Zachtonics [Last Call BBS](https://store.steampowered.com/app/1511780/Last_Call_BBS).

Theres still a lot of TODOS here to make it a full fledge game. I have to finish the winning states. And also include things like
a title screen/etc. This was mostly a fun project just to learn Odin and Raylib.

## Compiling and playing

This game compiles to both a desktop build, and a web wasm build! Based on:

https://github.com/karl-zylinski/odin-raylib-web


## Desktop build
```
build_desktop.sh
```

## WASM Web build

I programmed this game on a mac. The wasm build might not work for you!

Install:
1) Get Odin and compile it on mac: https://odin-lang.org/docs/install/#macos
2) Get emscript: https://emscripten.org/docs/getting_started/downloads.html
3) You might have to modify the ./build_web.sh script. Specifically the `EMSCRIPTEN_SDK_DIR` (point it to where you cloned and built emsdk). Also the `files=` will be different on your system. (Point it to where you cloned and built Odin and find the vendor/raylib/wasm files)

Compile:
```
./build_web.sh
cd build/web
python3 -m http.server

Then you can load the game at localhost:8000
```

<img width="1313" alt="Screen Shot 2024-06-07 at 2 44 48 PM" src="https://github.com/mawaldne/solitrouble/assets/40419/dfbfcb80-d7d9-4c56-8932-895f9ecccba8">
<img width="1058" alt="Screenshot 2025-03-07 at 1 19 47 PM" src="https://github.com/user-attachments/assets/f1ad3e22-cb45-4dd9-9be9-ed32b48cd779" />

package game

import rl "vendor:raylib"
import "core:fmt"

Card :: struct {
    texture: rl.Texture2D,
    position: rl.Vector2
}

main :: proc() {
    rl.InitWindow(1280, 720, "Solitrouble")
    card := Card {
	texture = rl.LoadTexture("images/card_clubs_02.png"),
	position = rl.Vector2 { 640, 320 }
    }
    card_tint := rl.WHITE

    rl.SetTargetFPS(60);
    card_width := f32(card.texture.width)
    card_height := f32(card.texture.height)

    for !rl.WindowShouldClose() {
	if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
	    mouse_pos := rl.GetMousePosition();
	    if mouse_pos.x >= card.position.x &&
	       mouse_pos.x <= (card.position.x + card_width * 4) &&
	       mouse_pos.y >= card.position.y &&
	       mouse_pos.y <= (card.position.y + card_height * 4) {
		mouse_delta := rl.GetMouseDelta()

		card.position.x = card.position.x + mouse_delta.x
		card.position.y = card.position.y + mouse_delta.y
	    }
	}

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)

	draw_card_source := rl.Rectangle {
	    x = 0,
	    y = 0,
	    width = card_width,
	    height = card_height
	}

	draw_player_dest := rl.Rectangle {
	    x = card.position.x,
	    y = card.position.y,
	    width = card_width * 4,
	    height = card_height * 4,
	}

	rl.DrawTexturePro(
	    card.texture,
	    draw_card_source,
	    draw_player_dest, 0, 0, card_tint
	)
        rl.EndDrawing()
    }
    rl.CloseWindow()
}

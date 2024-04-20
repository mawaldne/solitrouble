package game

import rl "vendor:raylib"
import "core:fmt"

Card :: struct {
    texture: rl.Texture2D,
    position: rl.Vector2,
    moving: bool,
    tint: rl.Color
}

// Solitaire todo:

//Clicking on them brings them to the top of the list. So adjust array of
//Cards..

// How do you snap too other cards (with rules?)

// Shuffle into a deck - shuffle function


main :: proc() {
    rl.InitWindow(1280, 720, "Solitrouble")
    cards: [dynamic]Card
    append(&cards, Card {
	texture = rl.LoadTexture("images/card_clubs_03.png"),
	position = rl.Vector2 { 740, 420 },
	tint = rl.WHITE
    })
    append(&cards, Card {
	texture = rl.LoadTexture("images/card_clubs_02.png"),
	position = rl.Vector2 { 640, 320 },
	tint = rl.WHITE
    })
    rl.SetTargetFPS(60);
    card_moving := false

    index := 0
    for !rl.WindowShouldClose() {
	if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
	    mouse_pos := rl.GetMousePosition();
	    index = clicked_card(&cards, mouse_pos)
	    if index >= 0 {
		card_moving = true
	    }
	} else {
	    card_moving = false
	}

	if card_moving && index >= 0 {
	    mouse_delta := rl.GetMouseDelta()
	    cards[index].position.x = cards[index].position.x + mouse_delta.x
	    cards[index].position.y = cards[index].position.y + mouse_delta.y
	}

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)
	draw_cards(&cards)
	rl.EndDrawing()
    }
    rl.CloseWindow()
}

clicked_card :: proc(cards: ^[dynamic]Card, mouse_pos: rl.Vector2) -> int {
    for card, index in cards {
	card_width := f32(card.texture.width)
	card_height := f32(card.texture.height)

	if  mouse_pos.x >= card.position.x &&
	    mouse_pos.x <= (card.position.x + card_width * 4) &&
	    mouse_pos.y >= card.position.y &&
	    mouse_pos.y <= (card.position.y + card_height * 4) {
	    return index;
	}
    }
    return -1
}

draw_cards :: proc(cards: ^[dynamic]Card) {
    for card in cards {
	card_width := f32(card.texture.width)
	card_height := f32(card.texture.height)

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
	    draw_player_dest, 0, 0, card.tint
	)
    }
}


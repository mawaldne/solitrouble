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

// How do you snap too other cards (with rules?)

// Shuffle into a deck - shuffle function

// How do you grab a set of cards?

//Memory management? do we need to cleanup the array?







main :: proc() {
    rl.InitWindow(1280, 720, "Solitrouble")
    cards: [dynamic]Card
    append(&cards, Card {
	texture = rl.LoadTexture("images/card_clubs_02.png"),
	position = rl.Vector2 { 640, 320 },
	tint = rl.WHITE
    })
    append(&cards, Card {
	texture = rl.LoadTexture("images/card_clubs_03.png"),
	position = rl.Vector2 { 740, 420 },
	tint = rl.WHITE
    })
    append(&cards, Card {
	texture = rl.LoadTexture("images/card_clubs_04.png"),
	position = rl.Vector2 { 640, 320 },
	tint = rl.WHITE
    })

    defer delete(cards)

    rl.SetTargetFPS(60)
    card_moving := false

    card_position := 0
    for !rl.WindowShouldClose() {
	if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
	    if !card_moving {
		//Find clicked card, move to the end so its rendered on top
		mouse_pos := rl.GetMousePosition();
		card_position = find_clicked_card(&cards, mouse_pos)
		if card_position >= 0 {
		    bring_card_top(&cards, card_position)
		    card_moving = true
		}
	    }
	} else {
	    card_moving = false
	}

	if card_moving {
	    mouse_delta := rl.GetMouseDelta()
	    cards[len(cards)-1].position.x = cards[len(cards)-1].position.x + mouse_delta.x
	    cards[len(cards)-1].position.y = cards[len(cards)-1].position.y + mouse_delta.y
	}

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)
	draw_cards(&cards)
	rl.EndDrawing()
    }
    rl.CloseWindow()
}


bring_card_top :: proc(cards: ^[dynamic]Card, index: int) {
    if index >= 0 && index != len(cards) - 1 {
	moved_card := cards[index]
	ordered_remove(cards, index)
	append(cards, moved_card)
    }
}

find_clicked_card :: proc(cards: ^[dynamic]Card, mouse_pos: rl.Vector2) -> int {
    //Reversed because this is the rendering order
    #reverse for card, index in cards {
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


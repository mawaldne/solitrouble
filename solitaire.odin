package game

import rl "vendor:raylib"
import "core:fmt"


// Solitaire todo:

// Fix grabbing bug. Holding down click and going over cards.
// Grab stacks of cards, and snap them. Be able to grab snapped groupings of cards.

// fix odin formatting and tabbing
// Add the proper rules around snapping. Red on black with decreasing value.
// Shuffle into a deck - shuffle function
// How do you grab a set of cards?
// Check the ALL 4 corners to see if they over lap another cards area?
// Nicer background
// Memory management? do we need to cleanup the array? tracking allocator?
// Screen size. Full screen and changing scale of things?


Card :: struct {
    texture: rl.Texture2D,
    position: rl.Vector2,
    snap_to_position: rl.Vector2,
    tint: rl.Color,
    scale: i32
}

main :: proc() {
    rl.InitWindow(1280, 720, "Solitrouble")
    cards: [dynamic]Card
    append(&cards, Card {
	texture = rl.LoadTexture("images/card_clubs_02.png"),
	position = rl.Vector2 { 340, 320 },
	tint = rl.WHITE,
	scale = 2
    })
    append(&cards, Card {
	texture = rl.LoadTexture("images/card_clubs_03.png"),
	position = rl.Vector2 { 440, 320 },
	tint = rl.WHITE,
	scale = 2
    })
    append(&cards, Card {
	texture = rl.LoadTexture("images/card_clubs_04.png"),
	position = rl.Vector2 { 540, 320 },
	tint = rl.WHITE,
	scale = 2
    })

    append(&cards, Card {
	texture = rl.LoadTexture("images/card_clubs_05.png"),
	position = rl.Vector2 { 640, 320 },
	snap_to_position = rl.Vector2 { 640, 320 },
	tint = rl.WHITE,
	scale = 2
    })

    defer delete(cards)

    rl.SetTargetFPS(60)
    card_moving := false

    for !rl.WindowShouldClose() {
	if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
	    if !card_moving {
		mouse_pos := rl.GetMousePosition();
		card_moving = find_clicked_card(&cards, mouse_pos)
	    } else {
		mouse_delta := rl.GetMouseDelta()
		cards[len(cards)-1].position.x = cards[len(cards)-1].position.x + mouse_delta.x
		cards[len(cards)-1].position.y = cards[len(cards)-1].position.y + mouse_delta.y

		find_overlapped_card(&cards)
	    }
	} else {
	    card_moving = false
	}

	if !card_moving {
	    cards[len(cards)-1].position.x = cards[len(cards)-1].snap_to_position.x
	    cards[len(cards)-1].position.y = cards[len(cards)-1].snap_to_position.y
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
	moved_card.snap_to_position.x = moved_card.position.x
	moved_card.snap_to_position.y = moved_card.position.y

	//TODO - do I need to free this?
	ordered_remove(cards, index)
	append(cards, moved_card)
    }
}

find_clicked_card :: proc(cards: ^[dynamic]Card, mouse_pos: rl.Vector2) -> bool {
    //Reversed because this is the rendering order
    #reverse for card, index in cards {
	card_width := f32(card.texture.width * card.scale)
	card_height := f32(card.texture.height * card.scale)

	if  mouse_pos.x >= card.position.x &&
	    mouse_pos.x <= (card.position.x + card_width) &&
	    mouse_pos.y >= card.position.y &&
	    mouse_pos.y <= (card.position.y + card_height) {
	    //Find clicked card, move to the end so its rendered on top
	    bring_card_top(cards, index)
	    return true
	}
    }
    return false
}

find_overlapped_card :: proc(cards: ^[dynamic]Card) {
    //Top card will always be the one moving
    top_card := &cards[len(cards) - 1]

    //Reversed because this is the rendering order
    #reverse for card in cards[:len(cards)-1] {
	card_width := f32(card.texture.width * card.scale)
	card_height := f32(card.texture.height * card.scale)

	//TODO: eventually check all 4 corners
	if  top_card.position.x >= card.position.x &&
	    top_card.position.x <= (card.position.x + card_width) &&
	    top_card.position.y >= card.position.y &&
	    top_card.position.y <= (card.position.y + card_height) {
		top_card.snap_to_position.x = card.position.x
		top_card.snap_to_position.y = card.position.y + 20
		return
	}
    }
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
	    width = card_width * f32(card.scale),
	    height = card_height * f32(card.scale),
	}

	rl.DrawTexturePro(
	    card.texture,
	    draw_card_source,
	    draw_player_dest, 0, 0, card.tint
	)
    }
}


package game

import rl "vendor:raylib"
import "core:fmt"


// Solitaire todo:

//BUG: How do we deal with stacks with nothing in them?

// Add the proper rules around snapping. Red on black with decreasing value.
// Shuffle into a deck - shuffle function
// How do you grab a set of cards?
// Check the ALL 4 corners to see if they over lap another cards area?
// Nicer background
// Memory management? do we need to cleanup the array? tracking allocator?
// Screen size. Full screen and changing scale of things?
// fix odin formatting and tabbing


Card :: struct {
    texture: rl.Texture2D,
    position: rl.Vector2,
    scale: i32
}


main :: proc() {
    rl.InitWindow(1280, 720, "Solitrouble")

    card_stack1: [dynamic]Card
    append(&card_stack1, Card {
	texture = rl.LoadTexture("images/card_clubs_02.png"),
	position = rl.Vector2 { 340, 320 },
	scale = 2
    })
    append(&card_stack1, Card {
	texture = rl.LoadTexture("images/card_clubs_03.png"),
	position = rl.Vector2 { 340, 350 },
	scale = 2
    })
    append(&card_stack1, Card {
	texture = rl.LoadTexture("images/card_clubs_04.png"),
	position = rl.Vector2 { 340, 380 },
	scale = 2
    })

    card_stack2: [dynamic]Card
    append(&card_stack2, Card {
	texture = rl.LoadTexture("images/card_clubs_05.png"),
	position = rl.Vector2 { 440, 320 },
	scale = 2
    })
    append(&card_stack2, Card {
	texture = rl.LoadTexture("images/card_clubs_06.png"),
	position = rl.Vector2 { 440, 350 },
	scale = 2
    })
    append(&card_stack2, Card {
	texture = rl.LoadTexture("images/card_clubs_07.png"),
	position = rl.Vector2 { 440, 380 },
	scale = 2
    })

    card_stacks: [dynamic][dynamic]Card
    append(&card_stacks, card_stack1)
    append(&card_stacks, card_stack2)

    defer delete(card_stacks)

    rl.SetTargetFPS(60)

    cards_moving: bool
    clicked_slice: [dynamic]Card
    previous_stack: ^[dynamic]Card

    overlapped: bool
    next_stack: ^[dynamic]Card

    for !rl.WindowShouldClose() {
	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
	    if !cards_moving {
		clicked_slice, previous_stack, cards_moving =
		    find_clicked_slice(&card_stacks, rl.GetMousePosition())
	    }
	}

	if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
	    cards_moving = false
	    next_stack, overlapped =
		find_overlapped_stack(&card_stacks, &clicked_slice)
	}

	if cards_moving {
	    mouse_delta := rl.GetMouseDelta()
	    //Draw the moving slice.
	    for i in 0..<len(clicked_slice) {
		clicked_slice[i].position.x += mouse_delta.x
		clicked_slice[i].position.y += mouse_delta.y
	    }
	} else {
	    if overlapped {
		//Get the last card in the stack
		last_card_position := next_stack[len(next_stack) - 1].position
		for i in 0..<len(clicked_slice) {
		    clicked_slice[i].position = rl.Vector2 {
			last_card_position.x, last_card_position.y + f32(30 * (i + 1))
		    }
	 	}
		overlapped = false
		append(next_stack, ..clicked_slice[:])
		clicked_slice = nil
	    } else if clicked_slice != nil {
		last_card_position := previous_stack[len(previous_stack) - 1].position
		for i in 0..<len(clicked_slice) {
		    clicked_slice[i].position = rl.Vector2 {
			last_card_position.x, last_card_position.y + f32(30 * (i + 1))
		    }
	 	}

		append(previous_stack, ..clicked_slice[:])
		clicked_slice = nil
	    }
	}

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)

	//Draw all cards
	for i in 0..<len(card_stacks) {
	    draw_cards(&card_stacks[i])
	}
	//Draw the moving slice if exists
	draw_cards(&clicked_slice)

	rl.EndDrawing()
    }
    rl.CloseWindow()
}

find_clicked_slice:: proc(card_stacks: ^[dynamic][dynamic]Card, mouse_pos: rl.Vector2) -> ([dynamic]Card, ^[dynamic]Card, bool) {
    for card_stack, card_stack_index in card_stacks {
	cards := card_stack
	//Reversed because this is the rendering order and we want to select the top one first
	//TODO: consider just using index to iterate?
	#reverse for card, card_index in cards {
	    card_width := f32(card.texture.width * card.scale)
	    card_height := f32(card.texture.height * card.scale)

	    if  mouse_pos.x >= card.position.x &&
		mouse_pos.x <= (card.position.x + card_width) &&
		mouse_pos.y >= card.position.y &&
		mouse_pos.y <= (card.position.y + card_height) {

		//Copy the clicked slice
		clicked_slice := card_stacks[card_stack_index][card_index:len(cards)]
		clicked_slice_copy := make([dynamic]Card, len(clicked_slice))
		copy(clicked_slice_copy[:], clicked_slice[:])

		//Delete from current stack
		remove_range(&card_stacks[card_stack_index], card_index, len(card_stacks[card_stack_index]))


		return clicked_slice_copy, &card_stacks[card_stack_index], true
	    }
	}
    }
    return nil, nil, false
}

find_overlapped_stack :: proc(card_stacks: ^[dynamic][dynamic]Card, clicked_slice: ^[dynamic]Card) -> (^[dynamic]Card, bool) {
    if clicked_slice == nil || len(clicked_slice) == 0 {
	return nil, false
    }
    top_card := clicked_slice[0]
    for card_stack, card_stack_index in card_stacks {
	cards := card_stack
	//Reversed because this is the rendering order and we want to select the top one first
	//TODO: consider just using index to iterate?
	#reverse for card, card_index in cards {
	    card_width := f32(card.texture.width * card.scale)
	    card_height := f32(card.texture.height * card.scale)
	    //todo: eventually check all 4 corners
	    if  top_card.position.x >= card.position.x &&
		top_card.position.x <= (card.position.x + card_width) &&
		top_card.position.y >= card.position.y &&
		top_card.position.y <= (card.position.y + card_height) {
		    return &card_stacks[card_stack_index], true
	    }
	}
    }

    return nil, false
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
	    draw_player_dest, 0, 0, rl.WHITE
	)
    }
}


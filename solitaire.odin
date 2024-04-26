package game

import rl "vendor:raylib"
import "core:fmt"


// Solitaire todo:

//Stack sections to put cards?

// Grab stacks of cards, and snap them. Be able to grab snapped groupings of cards.
// Should only be able to grab top cards on stack
    //stacks ? -



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
    snap_to_position: rl.Vector2,
    scale: i32
}


Stack :: struct {
    position: rl.Vector2,
}

main :: proc() {
    rl.InitWindow(1280, 720, "Solitrouble")
    //todo - stacks will contain cards. render cards in each stack.
    //Move cards onto the new stacks!

    cards: [dynamic]Card
    append(&cards, Card {
	texture = rl.LoadTexture("images/card_clubs_02.png"),
	position = rl.Vector2 { 340, 320 },
	scale = 2
    })
    append(&cards, Card {
	texture = rl.LoadTexture("images/card_clubs_03.png"),
	position = rl.Vector2 { 440, 320 },
	scale = 2
    })
    append(&cards, Card {
	texture = rl.LoadTexture("images/card_clubs_04.png"),
	position = rl.Vector2 { 540, 320 },
	snap_to_position = rl.Vector2 { 640, 320 },
	scale = 2
    })

    stacks := [1]Stack{
	{rl.Vector2 { 240, 320 }}
    }

    defer delete(cards)

    rl.SetTargetFPS(60)

    cards_moving: bool
    overlapped: bool
    overlapped_card: ^Card
    clicked_card: ^Card
    index: int

    for !rl.WindowShouldClose() {
	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
	    if !cards_moving {
		clicked_card, cards_moving = handle_clicked_card(&cards)
	    }
	}

	if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
	    cards_moving = false
	    overlapped_card, overlapped = find_overlapped_card(&cards, clicked_card)
	}

	if cards_moving {
	    mouse_delta := rl.GetMouseDelta()
	    clicked_card.position.x += mouse_delta.x
	    clicked_card.position.y += mouse_delta.y
	} else {
	    if overlapped {
		clicked_card.position = rl.Vector2 {
		overlapped_card.position.x,
		overlapped_card.position.y + 30
		}
	    }
	    overlapped = false
	    // for card in cards {
	    //     fmt.printf("%v %v\n", card.position)
	    // }
	}

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)
	draw_stacks(&stacks)
	draw_cards(&cards)
	rl.EndDrawing()
    }
    rl.CloseWindow()
}


bring_stack_top :: proc(cards: ^[dynamic]Card, index: int) {
    if index >= 0 && index != len(cards) - 1 {
	moved_card := cards[index]
	moved_card.snap_to_position.x = moved_card.position.x
	moved_card.snap_to_position.y = moved_card.position.y

	//TODO - do I need to free this?
	ordered_remove(cards, index)
	append(cards, moved_card)
    }
}

handle_clicked_card :: proc(cards: ^[dynamic]Card) -> (^Card, bool) {
    index := find_clicked_card(cards, rl.GetMousePosition())
    if index >= 0 {
        bring_stack_top(cards, index)
        return &cards[len(cards) - 1], true
    }
    return nil, false
}

find_clicked_card :: proc(cards: ^[dynamic]Card, mouse_pos: rl.Vector2) -> int {
    //Reversed because this is the rendering order
    #reverse for card, index in cards {
	card_width := f32(card.texture.width * card.scale)
	card_height := f32(card.texture.height * card.scale)

	if  mouse_pos.x >= card.position.x &&
	    mouse_pos.x <= (card.position.x + card_width) &&
	    mouse_pos.y >= card.position.y &&
	    mouse_pos.y <= (card.position.y + card_height) {

	    return index
	}
    }
    return -1
}

find_overlapped_card :: proc(cards: ^[dynamic]Card, top_card: ^Card) -> (^Card, bool) {
    //Potentially only need to check the top card of each stack...Since you can
    //over lap cards below...

    if top_card == nil {
	return nil, false
    }

    //Reversed because this is the rendering order
    #reverse for card, index in cards[:len(cards)-1] {
	card_width := f32(card.texture.width * card.scale)
	card_height := f32(card.texture.height * card.scale)

	//TODO: eventually check all 4 corners
	if  top_card.position.x >= card.position.x &&
	    top_card.position.x <= (card.position.x + card_width) &&
	    top_card.position.y >= card.position.y &&
	    top_card.position.y <= (card.position.y + card_height) {
		return &cards[index], true
	}
    }
    return nil, false
}

draw_stacks :: proc(stacks: ^[1]Stack) {
    for stack in stacks {
	rl.DrawRectangleV(
	    stack.position,
	    rl.Vector2 {42 * 2, 60 * 2},
	    rl.BLACK
	)
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
	    draw_player_dest, 0, 0, rl.WHITE
	)
    }
}


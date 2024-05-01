package game

import rl "vendor:raylib"
import "core:fmt"

// Solitaire todo:

//When you pull off deck, next card clickable...

// Add the proper rules around snapping. Red on black with decreasing value.

// Create a deck we can pull cards off of
// Click on deck makes the waste open up 3 more cards

// Create a nicer way to load cards
// Shuffle into a deck - shuffle function

// WINNING STATE! How do you win

// Check the ALL 4 corners to see if they over lap another cards area?

// UNDO! how... array of things that happened? The stack name and the card that went there.
// Reverse this array

// Nicer background

// Memory management? do we need to cleanup the array? tracking allocator?

// Screen size. Full screen and changing scale of things?

  //TODO - Now you need to check each stack in the game state object? Which stack did you click on. And what is the previous stack. etc
    //Note, you usually only need to check the last card of each stack. That is the only place you will over over fyi...
    //You can click on other cards though... OH WAIT. at the start of the game, all certain cards are not clickable either unless they match
    //rules...So you will need to keep that state up to date too! ARG...

Card :: struct {
    texture: rl.Texture2D,
    position: rl.Vector2,
    scale: i32,

    // Can click this card
    clickable: bool,
    // Can have cards stacked on it
    stackable: bool
}

Pile :: struct {
    cards: [dynamic]Card,
    position: rl.Vector2,
    stack_direction: rl.Vector2
}

Game_Board :: struct {
    stock_pile: Pile,
    tableau: [dynamic]Pile,
    foundation: [dynamic]Pile,
}

main :: proc() {
    rl.InitWindow(1280, 720, "Solitrouble")

    game_board: Game_Board
    setup_game_board(&game_board)

    //TODO?
    //defer delete(game_board.stock_pile)
    //defer delete(game_board.tableau)
    //defer delete(game_board.foundation)

    rl.SetTargetFPS(60)

    cards_moving: bool
    moving_cards: [dynamic]Card

    over_pile: bool
    previous_pile: ^Pile
    next_pile: ^Pile

    for !rl.WindowShouldClose() {
        if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
            if !cards_moving {
                moving_cards, previous_pile, cards_moving = get_clicked_cards(&game_board)
            }
        }

        if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
            cards_moving = false
            next_pile, over_pile = get_overlapped_pile(&game_board, &moving_cards)
        }

        if cards_moving {
            mouse_delta := rl.GetMouseDelta()
            //Draw the moving slice.
            for i in 0..<len(moving_cards) {
                moving_cards[i].position.x += mouse_delta.x
                moving_cards[i].position.y += mouse_delta.y
            }
        } else {
            if over_pile {
                //Get the last card in the stack
                last_card_position := next_pile.cards[len(next_pile.cards) - 1].position
                for i in 0..<len(moving_cards) {
                    moving_cards[i].position = last_card_position + next_pile.stack_direction
                    moving_cards[i].stackable = true
                    moving_cards[i].clickable = true
                }
                over_pile = false
                append(&next_pile.cards, ..moving_cards[:])
            } else if moving_cards != nil {
                last_card_position := previous_pile.cards[len(previous_pile.cards) - 1].position
                for i in 0..<len(moving_cards) {
                    moving_cards[i].position = last_card_position + previous_pile.stack_direction
                }
                append(&previous_pile.cards, ..moving_cards[:])
            }
            moving_cards = nil
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)

        //Draw all cards
        draw_cards(&game_board.stock_pile.cards)
        for i in 0..<len(game_board.tableau) {
            draw_cards(&game_board.tableau[i].cards)
        }
        for i in 0..<len(game_board.foundation) {
            draw_cards(&game_board.foundation[i].cards)
        }

        //Draw the moving cards if exists
        draw_cards(&moving_cards)

        rl.EndDrawing()
    }
    rl.CloseWindow()
}

get_clicked_cards :: proc(game_board: ^Game_Board) -> ([dynamic]Card, ^Pile, bool) {
    moving_cards: [dynamic]Card
    cards_moving: bool

    moving_cards, cards_moving = find_clicked_cards(&game_board.stock_pile.cards)
    if cards_moving {
        return moving_cards, &game_board.stock_pile, cards_moving
    }

    for i in 0..<len(game_board.tableau) {
        moving_cards, cards_moving = find_clicked_cards(&game_board.tableau[i].cards)
        if cards_moving {
            return moving_cards, &game_board.tableau[i], cards_moving
        }
    }
    for i in 0..<len(game_board.foundation) {
        moving_cards, cards_moving = find_clicked_cards(&game_board.foundation[i].cards)
        if cards_moving {
            return moving_cards, &game_board.foundation[i], cards_moving
        }
    }
    return nil, nil, false
}


find_clicked_cards :: proc(pile: ^[dynamic]Card) -> ([dynamic]Card, bool) {
    mouse_pos := rl.GetMousePosition()
    //Reversed because this is the rendering order and we want to select the top one first
    //TODO: consider just using index to iterate?
    #reverse for card, card_index in pile {
        card_width := f32(card.texture.width * card.scale)
        card_height := f32(card.texture.height * card.scale)

        if mouse_pos.x >= card.position.x &&
           mouse_pos.x <= (card.position.x + card_width) &&
           mouse_pos.y >= card.position.y &&
           mouse_pos.y <= (card.position.y + card_height) &&
           card.clickable {
            //Copy the clicked slice
            clicked_slice := pile[card_index:len(pile)]
            clicked_slice_copy := make([dynamic]Card, len(clicked_slice))
            copy(clicked_slice_copy[:], clicked_slice[:])

            //Delete from current pile
            remove_range(pile, card_index, len(pile))

            return clicked_slice_copy, true
        }
    }
    return nil, false
}

get_overlapped_pile :: proc(game_board: ^Game_Board, moving_cards: ^[dynamic]Card) -> (^Pile, bool) {
    overlapped: bool

    overlapped = find_overlapped_pile(&game_board.stock_pile.cards, moving_cards)
    if overlapped {
        return &game_board.stock_pile, overlapped
    }

    for i in 0..<len(game_board.tableau) {
        overlapped = find_overlapped_pile(&game_board.tableau[i].cards, moving_cards)
        if overlapped {
            return &game_board.tableau[i], overlapped
        }
    }
    for i in 0..<len(game_board.foundation) {
        overlapped = find_overlapped_pile(&game_board.foundation[i].cards, moving_cards)
        if overlapped {
            return &game_board.foundation[i], overlapped
        }
    }
    return nil, false
}

find_overlapped_pile :: proc(cards: ^[dynamic]Card, moving_cards: ^[dynamic]Card) -> (bool) {
    if moving_cards == nil || len(moving_cards) == 0 {
        return false
    }

    //only check if the top card is hoverover over another pile
    top_card := moving_cards[0]

    //Reversed because this is the rendering order and we want to select the top one first
    #reverse for card in cards {
        card_width := f32(card.texture.width * card.scale)
        card_height := f32(card.texture.height * card.scale)

        //todo: eventually check all 4 corners
        if  top_card.position.x >= card.position.x &&
            top_card.position.x <= (card.position.x + card_width) &&
            top_card.position.y >= card.position.y &&
            top_card.position.y <= (card.position.y + card_height) &&
            card.stackable {
            return true
        }
    }

    return false
}

draw_cards :: proc(cards: ^[dynamic]Card) {
    if cards == nil || len(cards) == 0 {
        return
    }

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

setup_game_board :: proc(game_board: ^Game_Board) {

    stock_pile := Pile {
       position = rl.Vector2 { 140, 25 },
       stack_direction = rl.Vector2 { 30, 0 }
    }
    add_card_pile(&stock_pile, "images/card_back.png", 0, 2, false, false)
    add_card_pile(&stock_pile, "images/card_clubs_09.png", 1, 2, false, false)
    add_card_pile(&stock_pile, "images/card_diamonds_08.png", 2, 2, false, false)
    add_card_pile(&stock_pile, "images/card_clubs_07.png", 3, 2, true, false)
    game_board.stock_pile = stock_pile

    //7 decks in tableau
    tableau1 := Pile {
       position = rl.Vector2 { 340, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau1, "images/card_back.png", 0, 2, false, true)

    tableau2 := Pile {
       position = rl.Vector2 { 440, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau2, "images/card_back.png", 0, 2, false, true)

    tableau3 := Pile {
       position = rl.Vector2 { 540, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau3, "images/card_back.png", 0, 2, false, true)

    tableau4 := Pile {
       position = rl.Vector2 { 640, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau4, "images/card_back.png", 0, 2, false, true)

    tableau5 := Pile {
       position = rl.Vector2 { 740, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau5, "images/card_back.png", 0, 2, false, true)

    tableau6 := Pile {
       position = rl.Vector2 { 840, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau6, "images/card_back.png", 0, 2, false, true)

    tableau7 := Pile {
       position = rl.Vector2 { 940, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau7, "images/card_back.png", 0, 2, false, true)

    tableau: [dynamic]Pile
    append(&tableau, tableau1)
    append(&tableau, tableau2)
    append(&tableau, tableau3)
    append(&tableau, tableau4)
    append(&tableau, tableau5)
    append(&tableau, tableau6)
    append(&tableau, tableau7)
    game_board.tableau = tableau

    //4 decks in foundation
    foundation1 := Pile {
       position = rl.Vector2 { 140, 190 },
       stack_direction = rl.Vector2 { 0, 0 }
    }
    add_card_pile(&foundation1, "images/card_back.png", 0, 2, false, true)

    foundation2 := Pile {
       position = rl.Vector2 { 140, 320 },
       stack_direction = rl.Vector2 { 0, 0 }
    }
    add_card_pile(&foundation2, "images/card_back.png", 0, 2, false, true)

    foundation3 := Pile {
       position = rl.Vector2 { 140, 450 },
       stack_direction = rl.Vector2 { 0, 0 }
    }
    add_card_pile(&foundation3, "images/card_back.png", 0, 2, false, true)

    foundation4 := Pile {
       position = rl.Vector2 { 140, 580 },
       stack_direction = rl.Vector2 { 0, 0 }
    }
    add_card_pile(&foundation4, "images/card_back.png", 0, 2, false, true)

    foundation: [dynamic]Pile
    append(&foundation, foundation1)
    append(&foundation, foundation2)
    append(&foundation, foundation3)
    append(&foundation, foundation4)
    game_board.foundation = foundation
}


add_card_pile :: proc(
    pile: ^Pile,
    texture_name: cstring,
    card_position: f32,
    scale: i32,
    clickable: bool,
    stackable: bool
) {
    append(&pile.cards, Card {
        texture = rl.LoadTexture(texture_name),
        position = pile.position + (pile.stack_direction * card_position),
        scale = scale,
        clickable = clickable,
        stackable = stackable
    })
}

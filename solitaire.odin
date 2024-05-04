package game

import rl "vendor:raylib"
import "core:fmt"

// Solitaire todo:

// Add the proper rules around snapping. Red on black with decreasing value.

// Create a deck we can pull cards off of
// Create all the cards in each tableau. Make sure clickable states are correct.
// Click on deck makes the waste open up 3 more cards

// Shuffle into a deck - shuffle function

// WINNING STATE! How do you win

// Check the ALL 4 corners to see if they over lap another cards area?

// UNDO! how... array of things that happened? The stack name and the card that went there.
// Reverse this array

// Nicer background

// Memory management? do we need to cleanup the array? tracking allocator?

// Screen size. Full screen and changing scale of things?

CardColor :: enum{Red, Black}

CARD_SCALE :: 2

Card :: struct {
    texture: rl.Texture2D,
    position: rl.Vector2,

    clickable: bool,
    stackable: bool,

    rank: u8,
    color: CardColor
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
    //Clean up memory?

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
                    moving_cards[i].position = last_card_position + (next_pile.stack_direction * f32(1 + i))
                    moving_cards[i].stackable = true
                    moving_cards[i].clickable = true
                }
                over_pile = false

                //This makes the stock pile last card clickable
                if len(previous_pile.cards) > 1 {
                    previous_pile.cards[len(previous_pile.cards) - 1].clickable = true
                }

                append(&next_pile.cards, ..moving_cards[:])
            } else if moving_cards != nil {
                last_card_position := previous_pile.cards[len(previous_pile.cards) - 1].position
                for i in 0..<len(moving_cards) {
                    moving_cards[i].position = last_card_position + (previous_pile.stack_direction * f32(1 + i))
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
        card_width := f32(card.texture.width * CARD_SCALE)
        card_height := f32(card.texture.height * CARD_SCALE)

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
    top_card_pile: Card
    bottom_moving_card: Card

    for i in 0..<len(game_board.tableau) {
        overlapped, top_card_pile, bottom_moving_card =
            find_overlapped_pile(&game_board.tableau[i].cards, moving_cards)
        //todo Probably not the right spot for this?
        if overlapped &&
            (len(&game_board.tableau[i].cards) == 1 ||
            (top_card_pile.color == CardColor.Red && bottom_moving_card.color == CardColor.Black) ||
            (top_card_pile.color == CardColor.Black && bottom_moving_card.color == CardColor.Red)) &&
            bottom_moving_card.rank < top_card_pile.rank {
            return &game_board.tableau[i], overlapped
        }
    }
    if (len(moving_cards) == 1) {
        for i in 0..<len(game_board.foundation) {
            overlapped, top_card_pile, bottom_moving_card =
                find_overlapped_pile(&game_board.foundation[i].cards, moving_cards)

            if overlapped &&
                (len(&game_board.foundation[i].cards) == 1 || top_card_pile.color == bottom_moving_card.color) &&
                (top_card_pile.rank + 1) == bottom_moving_card.rank {
                return &game_board.foundation[i], overlapped
            }
        }
    }
    return nil, false
}

find_overlapped_pile :: proc(cards: ^[dynamic]Card, moving_cards: ^[dynamic]Card) -> (bool, Card, Card) {
    if moving_cards == nil || len(moving_cards) == 0 {
        return false, Card {}, Card {}
    }

    //only check if the bottom card is hoverover over another pile
    bottom_moving_card := moving_cards[0]

    //Only check the last card (top card) in the pile
    top_card_pile := cards[len(cards) - 1]

    top_card_pile_width := f32(top_card_pile.texture.width * CARD_SCALE)
    top_card_pile_height := f32(top_card_pile.texture.height * CARD_SCALE)

    //todo: eventually check all 4 corners
    if (bottom_moving_card.position.x >= top_card_pile.position.x &&
        bottom_moving_card.position.x <= (top_card_pile.position.x + top_card_pile_width) &&
        bottom_moving_card.position.y >= top_card_pile.position.y &&
        bottom_moving_card.position.y <= (top_card_pile.position.y + top_card_pile_height) &&
        top_card_pile.stackable) {
            return true, top_card_pile, bottom_moving_card
        }
        return false, Card {}, Card {}
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
            width = card_width * f32(CARD_SCALE),
            height = card_height * f32(CARD_SCALE),
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
    add_card_pile(&stock_pile, "images/card_back.png", 14, CardColor.Black,false, false)

    add_card_pile(&stock_pile, "images/card_diamonds_A.png", 1, CardColor.Red,false, false)
    add_card_pile(&stock_pile, "images/card_clubs_A.png", 1, CardColor.Black,false, false)

    add_card_pile(&stock_pile, "images/card_diamonds_02.png", 2, CardColor.Red,false, false)
    add_card_pile(&stock_pile, "images/card_clubs_02.png", 2, CardColor.Black,false, false)

    add_card_pile(&stock_pile, "images/card_diamonds_03.png", 3, CardColor.Red,false, false)
    add_card_pile(&stock_pile, "images/card_clubs_03.png", 3, CardColor.Black,false, false)

    add_card_pile(&stock_pile, "images/card_diamonds_04.png", 4, CardColor.Red,false, false)
    add_card_pile(&stock_pile, "images/card_clubs_04.png", 4, CardColor.Black,false, false)

    add_card_pile(&stock_pile, "images/card_diamonds_05.png", 5, CardColor.Red,false, false)
    add_card_pile(&stock_pile, "images/card_clubs_05.png", 5, CardColor.Black,false, false)

    add_card_pile(&stock_pile, "images/card_diamonds_06.png", 6, CardColor.Red,false, false)
    add_card_pile(&stock_pile, "images/card_clubs_06.png", 6, CardColor.Black,false, false)

    add_card_pile(&stock_pile, "images/card_diamonds_07.png", 7, CardColor.Red,false, false)
    add_card_pile(&stock_pile, "images/card_clubs_07.png", 7, CardColor.Black,false, false)

    add_card_pile(&stock_pile, "images/card_diamonds_08.png", 8, CardColor.Red,false, false)
    add_card_pile(&stock_pile, "images/card_clubs_08.png", 8, CardColor.Black,false, false)

    add_card_pile(&stock_pile, "images/card_diamonds_09.png", 9, CardColor.Red,false, false)
    add_card_pile(&stock_pile, "images/card_clubs_09.png", 9, CardColor.Black,false, false)

    add_card_pile(&stock_pile, "images/card_diamonds_10.png", 10, CardColor.Red,false, false)
    add_card_pile(&stock_pile, "images/card_clubs_10.png", 10, CardColor.Black,false, false)

    add_card_pile(&stock_pile, "images/card_diamonds_J.png", 11, CardColor.Red,false, false)
    add_card_pile(&stock_pile, "images/card_clubs_J.png", 11, CardColor.Black,false, false)

    add_card_pile(&stock_pile, "images/card_diamonds_Q.png", 12, CardColor.Red,false, false)
    add_card_pile(&stock_pile, "images/card_clubs_Q.png", 12, CardColor.Black,false, false)

    add_card_pile(&stock_pile, "images/card_diamonds_K.png", 13, CardColor.Red,false, false)
    add_card_pile(&stock_pile, "images/card_clubs_K.png", 13, CardColor.Black,true, false)

    game_board.stock_pile = stock_pile

    //7 decks in tableau
    tableau1 := Pile {
       position = rl.Vector2 { 340, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau1, "images/card_back.png", 14, CardColor.Black,false, true)

    tableau2 := Pile {
       position = rl.Vector2 { 440, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau2, "images/card_back.png", 14, CardColor.Black,false, true)

    tableau3 := Pile {
       position = rl.Vector2 { 540, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau3, "images/card_back.png", 14, CardColor.Black,false, true)

    tableau4 := Pile {
       position = rl.Vector2 { 640, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau4, "images/card_back.png", 14, CardColor.Black,false, true)

    tableau5 := Pile {
       position = rl.Vector2 { 740, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau5, "images/card_back.png", 14, CardColor.Black,false, true)

    tableau6 := Pile {
       position = rl.Vector2 { 840, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau6, "images/card_back.png", 14, CardColor.Black,false, true)

    tableau7 := Pile {
       position = rl.Vector2 { 940, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau7, "images/card_back.png", 14, CardColor.Black,false, true)

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
    add_card_pile(&foundation1, "images/card_back.png", 0, CardColor.Black,false, true)

    foundation2 := Pile {
       position = rl.Vector2 { 140, 320 },
       stack_direction = rl.Vector2 { 0, 0 }
    }
    add_card_pile(&foundation2, "images/card_back.png", 0, CardColor.Black,false, true)

    foundation3 := Pile {
       position = rl.Vector2 { 140, 450 },
       stack_direction = rl.Vector2 { 0, 0 }
    }
    add_card_pile(&foundation3, "images/card_back.png", 0, CardColor.Black,false, true)

    foundation4 := Pile {
       position = rl.Vector2 { 140, 580 },
       stack_direction = rl.Vector2 { 0, 0 }
    }
    add_card_pile(&foundation4, "images/card_back.png", 0, CardColor.Black, false, true)

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
    rank: u8,
    color: CardColor,
    clickable: bool,
    stackable: bool
) {
    append(&pile.cards, Card {
        texture = rl.LoadTexture(texture_name),
        position = pile.position + (pile.stack_direction * f32(len(pile.cards))),
        rank = rank,
        color = color,
        clickable = clickable,
        stackable = stackable
    })
}

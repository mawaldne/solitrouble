package game

import rl "vendor:raylib"
import "core:slice"
import "core:strings"
import "core:math/rand"
import "core:fmt"



// Solitaire todo:

// have a stack represented with upside down cards.
// Dont allow cards in continous stack to be clicked and moved!

// Create all the cards in each tableau. Make sure clickable states are correct.
// Click on deck makes the waste open up 3 more cards

// MAYBE = Remove the empty card in each stack! just use the pile position for the starting card?
// WINNING STATE! How do you win

// Check the ALL 4 corners to see if they over lap another cards area?

// UNDO! how... array of things that happened? The stack name and the card that went there.
// Reverse this array

// Nicer background

// Memory management? do we need to cleanup the array? tracking allocator?

// Screen size. Full screen and changing scale of things?

// Starting screens.
// Help screen.
// Reset game.



// Deck_Texture_Names := [dynamic]string {
//     "card_clubs_02.png", "card_clubs_03.png", "card_clubs_04.png", "card_clubs_05.png", "card_clubs_06.png",
//     "card_clubs_07.png", "card_clubs_08.png", "card_clubs_09.png", "card_clubs_10.png", "card_clubs_A.png",
//     "card_clubs_J.png", "card_clubs_K.png", "card_clubs_Q.png", "card_diamonds_02.png",
//     "card_diamonds_03.png", "card_diamonds_04.png", "card_diamonds_05.png", "card_diamonds_06.png",
//     "card_diamonds_07.png", "card_diamonds_08.png", "card_diamonds_09.png", "card_diamonds_10.png",
//     "card_diamonds_A.png", "card_diamonds_J.png", "card_diamonds_K.png", "card_diamonds_Q.png",
//     "card_hearts_02.png", "card_hearts_03.png", "card_hearts_04.png", "card_hearts_05.png",
//     "card_hearts_06.png", "card_hearts_07.png", "card_hearts_08.png", "card_hearts_09.png",
//     "card_hearts_10.png", "card_hearts_A.png", "card_hearts_J.png", "card_hearts_K.png",
//     "card_hearts_Q.png", "card_spades_02.png", "card_spades_03.png", "card_spades_04.png",
//     "card_spades_05.png", "card_spades_06.png", "card_spades_07.png", "card_spades_08.png",
//     "card_spades_09.png", "card_spades_10.png", "card_spades_A.png", "card_spades_J.png",
//     "card_spades_K.png", "card_spades_Q.png"
// }

Deck_Texture_Names := [dynamic]string {
    "card_clubs_02.png", "card_clubs_03.png", "card_clubs_04.png", "card_clubs_05.png", "card_clubs_06.png",
    "card_clubs_07.png", "card_clubs_08.png", "card_clubs_09.png", "card_clubs_10.png", "card_clubs_A.png",
    "card_clubs_J.png", "card_clubs_K.png", "card_clubs_Q.png", "card_diamonds_02.png",
    "card_diamonds_03.png", "card_diamonds_04.png", "card_diamonds_05.png", "card_diamonds_06.png",
    "card_diamonds_07.png", "card_diamonds_08.png", "card_diamonds_09.png", "card_diamonds_10.png",
    "card_diamonds_A.png", "card_diamonds_J.png", "card_diamonds_K.png", "card_diamonds_Q.png"
}


Card_Color :: enum{Red, Black, None}

CARD_SCALE :: 2

Card :: struct {
    texture: rl.Texture2D,
    position: rl.Vector2,

    clickable: bool,
    stackable: bool,

    rank: u8,
    color: Card_Color
}

Pile :: struct {
    cards: [dynamic]Card,
    position: rl.Vector2,
    stack_direction: rl.Vector2
}

Game_Board :: struct {
    stock: Pile,
    waste: Pile,
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

    stock_clicked: bool
    cards_moving: bool
    moving_cards: [dynamic]Card

    over_pile: bool
    previous_pile: ^Pile
    next_pile: ^Pile

    for !rl.WindowShouldClose() {
        if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
            if !cards_moving {
                //Check if we clicked on stock pile. If so update waste pile with 3 new cards
                stock_clicked = check_stock_clicked(&game_board)

                //Otherwise get clicked card from the waste/tableaus (you can't take from the foundation)
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
            } else if stock_clicked {

                //Copy the clicked slice
                if len(game_board.stock.cards) >= 3 {
                    waste_cards := game_board.stock.cards[len(game_board.stock.cards) - 3:len(game_board.stock.cards)]
                    waste_cards_copy := make([dynamic]Card, len(waste_cards))
                    copy(waste_cards_copy[:], waste_cards[:])

                    //Delete from current pile
                    remove_range(&game_board.stock.cards,len(game_board.stock.cards) - 3, len(game_board.stock.cards))

                    waste_bottom_card := bottom_card(&game_board.waste.cards)
                    append(&game_board.waste.cards, ..waste_cards_copy[:])
                    for i in 1..<len(game_board.waste.cards) {
                        game_board.waste.cards[i].position = waste_bottom_card.position + (game_board.waste.stack_direction * f32(i))
                        game_board.waste.cards[i].clickable = false
                    }
                    waste_top_card := top_card(&game_board.waste.cards)
                    waste_top_card.clickable = true
                }
                stock_clicked = false
            }
            moving_cards = nil
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)

        //Draw all cards
        draw_cards(&game_board.stock.cards)
        draw_cards(&game_board.waste.cards)
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

top_card :: proc(cards: ^[dynamic]Card) -> (^Card) {
    return &cards[len(cards) - 1]
}

bottom_card :: proc(cards: ^[dynamic]Card) -> (^Card) {
    return &cards[0]
}

check_stock_clicked :: proc(game_board: ^Game_Board) -> (bool) {
    mouse_pos := rl.GetMousePosition()

    //Only check the last card (top card) in the pile
    top_card_stock := game_board.stock.cards[len(game_board.stock.cards) - 1]

    card_width := f32(top_card_stock.texture.width * CARD_SCALE)
    card_height := f32(top_card_stock.texture.height * CARD_SCALE)

    return mouse_pos.x >= top_card_stock.position.x &&
       mouse_pos.x <= (top_card_stock.position.x + card_width) &&
       mouse_pos.y >= top_card_stock.position.y &&
       mouse_pos.y <= (top_card_stock.position.y + card_height)
}

get_clicked_cards :: proc(game_board: ^Game_Board) -> ([dynamic]Card, ^Pile, bool) {
    moving_cards: [dynamic]Card
    cards_moving: bool

    moving_cards, cards_moving = find_clicked_cards(&game_board.waste.cards)
    if cards_moving {
         return moving_cards, &game_board.waste, cards_moving
    }

    for i in 0..<len(game_board.tableau) {
        moving_cards, cards_moving = find_clicked_cards(&game_board.tableau[i].cards)
        if cards_moving {
            return moving_cards, &game_board.tableau[i], cards_moving
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
            check_if_overlapped_pile(&game_board.tableau[i].cards, moving_cards)

        if overlapped &&
            //Basic stacking game rules here!
            (len(&game_board.tableau[i].cards) == 1) ||
            (((top_card_pile.color == Card_Color.Red && bottom_moving_card.color == Card_Color.Black) ||
             (top_card_pile.color == Card_Color.Black && bottom_moving_card.color == Card_Color.Red)) &&
              top_card_pile.rank == (bottom_moving_card.rank + 1)) {
            return &game_board.tableau[i], overlapped
        }
    }
    if (len(moving_cards) == 1) {
        for i in 0..<len(game_board.foundation) {
            overlapped, top_card_pile, bottom_moving_card =
                check_if_overlapped_pile(&game_board.foundation[i].cards, moving_cards)

            if overlapped &&
                //Basic stacking game rules!
                (len(&game_board.foundation[i].cards) == 1 || top_card_pile.color == bottom_moving_card.color) &&
                (top_card_pile.rank + 1) == bottom_moving_card.rank {
                return &game_board.foundation[i], overlapped
            }
        }
    }
    return nil, false
}

check_if_overlapped_pile :: proc(cards: ^[dynamic]Card, moving_cards: ^[dynamic]Card) -> (bool, Card, Card) {
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
    //Shuffle the deck
    rand.shuffle(Deck_Texture_Names[:])

    stock := Pile {
       position = rl.Vector2 { 140, 25 },
       stack_direction = rl.Vector2 { 0, 0 }
    }

    add_card_pile(&stock, "card_back_stock.png")
    for i in 0..<len(Deck_Texture_Names) {
        add_card_pile(&stock, Deck_Texture_Names[i]);
    }
    //Only top card is clickable
    stock.cards[len(stock.cards) - 1].clickable = true
    game_board.stock = stock

    waste := Pile {
       position = rl.Vector2 { 230, 25 },
       stack_direction = rl.Vector2 { 30, 0 }
    }

    add_card_pile(&waste, "card_back_waste.png")
    game_board.waste = waste

    //7 decks in tableau
    tableau1 := Pile {
       position = rl.Vector2 { 340, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau1, "card_back_tableau.png")

    tableau2 := Pile {
       position = rl.Vector2 { 440, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau2, "card_back_tableau.png")

    tableau3 := Pile {
       position = rl.Vector2 { 540, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau3, "card_back_tableau.png")

    tableau4 := Pile {
       position = rl.Vector2 { 640, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau4, "card_back_tableau.png")

    tableau5 := Pile {
       position = rl.Vector2 { 740, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau5, "card_back_tableau.png")

    tableau6 := Pile {
       position = rl.Vector2 { 840, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau6, "card_back_tableau.png")

    tableau7 := Pile {
       position = rl.Vector2 { 940, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_card_pile(&tableau7, "card_back_tableau.png")

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
    add_card_pile(&foundation1, "card_back_foundation.png")

    foundation2 := Pile {
       position = rl.Vector2 { 140, 320 },
       stack_direction = rl.Vector2 { 0, 0 }
    }
    add_card_pile(&foundation2, "card_back_foundation.png")

    foundation3 := Pile {
       position = rl.Vector2 { 140, 450 },
       stack_direction = rl.Vector2 { 0, 0 }
    }
    add_card_pile(&foundation3, "card_back_foundation.png")

    foundation4 := Pile {
       position = rl.Vector2 { 140, 580 },
       stack_direction = rl.Vector2 { 0, 0 }
    }
    add_card_pile(&foundation4, "card_back_foundation.png")

    foundation: [dynamic]Pile
    append(&foundation, foundation1)
    append(&foundation, foundation2)
    append(&foundation, foundation3)
    append(&foundation, foundation4)
    game_board.foundation = foundation
}


add_card_pile :: proc(
    pile: ^Pile,
    texture_name: string
) {
    absolute_texture_file := strings.concatenate({"images/", texture_name})

    color: Card_Color
    rank: u8
    stackable: bool

    clubs := strings.contains(texture_name, "club")
    heart := strings.contains(texture_name, "heart")
    diamond := strings.contains(texture_name, "diamond")
    spade := strings.contains(texture_name, "spade")

    if diamond || heart {
        color = Card_Color.Red
    } else if clubs || spade {
        color = Card_Color.Black
    } else {
        color = Card_Color.None
    }

    if strings.contains(texture_name, "_foundation") {
        rank = 0
        stackable = true
    } else if strings.contains(texture_name, "_A") {
        rank = 1
    } else if strings.contains(texture_name, "_02") {
        rank = 2
    } else if strings.contains(texture_name, "_03") {
        rank = 3
    } else if strings.contains(texture_name, "_04") {
        rank = 4
    } else if strings.contains(texture_name, "_05") {
        rank = 5
    } else if strings.contains(texture_name, "_06") {
        rank = 6
    } else if strings.contains(texture_name, "_07") {
        rank = 7
    } else if strings.contains(texture_name, "_08") {
        rank = 8
    } else if strings.contains(texture_name, "_09") {
        rank = 9
    } else if strings.contains(texture_name, "_10") {
        rank = 10
    } else if strings.contains(texture_name, "_J") {
        rank = 11
    } else if strings.contains(texture_name, "_Q") {
        rank = 12
    } else if strings.contains(texture_name, "_K") {
        rank = 13
    } else if strings.contains(texture_name, "_tableau") {
        rank = 14
        stackable = true
    } else if strings.contains(texture_name, "_stock") {
        rank = 14
    } else if strings.contains(texture_name, "_waste") {
        rank = 14
    }


    append(&pile.cards, Card {
        texture = rl.LoadTexture(strings.clone_to_cstring(absolute_texture_file)),
        position = pile.position + (pile.stack_direction * f32(len(pile.cards))),
        rank = rank,
        color = color,
        stackable = stackable
    })
}



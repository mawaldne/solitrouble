package game

import rl "vendor:raylib"
import "core:slice"
import "core:strings"
import "core:math/rand"
import "core:fmt"



// Solitaire todo:

// WINNING STATE! How do you win

// Animate top corner...And make the card you hover over fade/or change color to stack?
// ANIMATE CARDS going into tableau
// Layered the stack so looks like many cards.
// Nicer background
// Memory management? do we need to cleanup the array? tracking allocator?
// Check the ALL 4 corners to see if they over lap another cards area?
// UNDO! how... array of things that happened? The stack name and the card that went there.
// Reset game.
// Screen size. Full screen and changing scale of things?
// Starting screens.
// Help screen.


deck_names := [dynamic]string {
    "card_clubs_02.png", "card_clubs_03.png", "card_clubs_04.png", "card_clubs_05.png", "card_clubs_06.png",
    "card_clubs_07.png", "card_clubs_08.png", "card_clubs_09.png", "card_clubs_10.png", "card_clubs_A.png",
    "card_clubs_J.png", "card_clubs_K.png", "card_clubs_Q.png", "card_diamonds_02.png",
    "card_diamonds_03.png", "card_diamonds_04.png", "card_diamonds_05.png", "card_diamonds_06.png",
    "card_diamonds_07.png", "card_diamonds_08.png", "card_diamonds_09.png", "card_diamonds_10.png",
    "card_diamonds_A.png", "card_diamonds_J.png", "card_diamonds_K.png", "card_diamonds_Q.png",
    "card_hearts_02.png", "card_hearts_03.png", "card_hearts_04.png", "card_hearts_05.png",
    "card_hearts_06.png", "card_hearts_07.png", "card_hearts_08.png", "card_hearts_09.png",
    "card_hearts_10.png", "card_hearts_A.png", "card_hearts_J.png", "card_hearts_K.png",
    "card_hearts_Q.png", "card_spades_02.png", "card_spades_03.png", "card_spades_04.png",
    "card_spades_05.png", "card_spades_06.png", "card_spades_07.png", "card_spades_08.png",
    "card_spades_09.png", "card_spades_10.png", "card_spades_A.png", "card_spades_J.png",
    "card_spades_K.png", "card_spades_Q.png"
}

Card_Color :: enum{Red, Black}

CARD_SCALE :: 2
CARD_WIDTH :: f32(42 * CARD_SCALE)
CARD_HEIGHT :: f32(60 * CARD_SCALE)

Card :: struct {
    name: string,
    texture: rl.Texture2D,
    position: rl.Vector2,

    clickable: bool,

    rank: u8,
    color: Card_Color
}

Pile :: struct {
    texture: rl.Texture2D,
    cards: [dynamic]Card,
    position: rl.Vector2,
    stack_direction: rl.Vector2
}

Game_Board :: struct {
    stock: Pile,
    waste: Pile,
    tableau: [dynamic]Pile,
    foundation: [dynamic]Pile,

    stock_exhausted: bool
}

main :: proc() {
    rl.InitWindow(1280, 720, "Solitrouble")

    game_board: Game_Board
    setup_game_board(&game_board)

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
                if !game_board.stock_exhausted {
                    stock_clicked = check_stock_clicked(&game_board)
                }

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
                for i in 0..<len(moving_cards) {
                    if i == 0 {
                        next_position := get_pile_stack_position(next_pile)
                        if len(next_pile.cards) == 0  {
                            moving_cards[i].position = next_position
                        } else {
                            moving_cards[i].position = next_position + next_pile.stack_direction
                        }
                    } else {
                        moving_cards[i].position = moving_cards[i - 1].position + next_pile.stack_direction
                    }
                    moving_cards[i].clickable = true
                }
                over_pile = false

                //This makes the previous pile last card clickable
                if len(previous_pile.cards) > 0 {
                    top_card(&previous_pile.cards).clickable = true
                }

                append(&next_pile.cards, ..moving_cards[:])
            } else if moving_cards != nil {
                for i in 0..<len(moving_cards) {
                    if i == 0 {
                        previous_position := get_pile_stack_position(previous_pile)
                        if len(previous_pile.cards) == 0  {
                            moving_cards[i].position = previous_position
                        } else {
                            moving_cards[i].position = previous_position + previous_pile.stack_direction
                        }
                    } else {
                        moving_cards[i].position = moving_cards[i - 1].position + previous_pile.stack_direction
                    }
                }
                append(&previous_pile.cards, ..moving_cards[:])
            } else if stock_clicked {
                if len(game_board.stock.cards) > 0 {
                    waste_cards := take_cards(&game_board.stock.cards, 3)
                    append(&game_board.waste.cards, ..waste_cards[:])

                    for i in 0..<len(game_board.waste.cards) {
                        game_board.waste.cards[i].position = game_board.waste.position + (game_board.waste.stack_direction * f32(i))
                        game_board.waste.cards[i].clickable = false
                    }
                    waste_top_card := top_card(&game_board.waste.cards)
                    waste_top_card.clickable = true
                }
                stock_clicked = false
            }
            moving_cards = nil
        }

        if !game_board.stock_exhausted && len(game_board.stock.cards) == 0 {
            game_board.stock_exhausted = true
            game_board.stock.texture = rl.LoadTexture("images/stock_stackable.png")
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)

        //Draw piles
        draw_pile(&game_board.waste)
        for i in 0..<len(game_board.tableau) {
            draw_pile(&game_board.tableau[i])
        }
        for i in 0..<len(game_board.foundation) {
            draw_pile(&game_board.foundation[i])
        }
        //Draw all cards
        draw_cards(&game_board.waste.cards)
        for i in 0..<len(game_board.tableau) {
            draw_cards(&game_board.tableau[i].cards)
        }
        for i in 0..<len(game_board.foundation) {
            draw_cards(&game_board.foundation[i].cards)
        }

        draw_pile(&game_board.stock)
        if game_board.stock_exhausted {
            draw_cards(&game_board.stock.cards)
        }

        //Draw the moving cards if exists
        draw_cards(&moving_cards)

        rl.EndDrawing()
    }
    rl.CloseWindow()
}

print_cards :: proc(cards: ^[dynamic]Card) {
    fmt.println("\n\n")
    for card in cards {
        fmt.printf("%v ", card.name)
    }
}

top_card :: proc(cards: ^[dynamic]Card) -> (^Card) {
    return &cards[len(cards) - 1]
}

bottom_card :: proc(cards: ^[dynamic]Card) -> (^Card) {
    return &cards[0]
}

get_pile_stack_position :: proc(pile: ^Pile) -> (rl.Vector2) {
    if len(pile.cards) == 0 {
        return pile.position
    }
    return top_card(&pile.cards).position
}

check_stock_clicked :: proc(game_board: ^Game_Board) -> (bool) {
    mouse_pos := rl.GetMousePosition()
    stock_pos := game_board.stock.position

    return mouse_pos.x >= stock_pos.x &&
       mouse_pos.x <= (stock_pos.x + CARD_WIDTH) &&
       mouse_pos.y >= stock_pos.y &&
       mouse_pos.y <= (stock_pos.y + CARD_HEIGHT)
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
    if (game_board.stock_exhausted) {
        moving_cards, cards_moving = find_clicked_cards(&game_board.stock.cards)
        if cards_moving {
             return moving_cards, &game_board.stock, cards_moving
        }
    }
    return nil, nil, false
}


find_clicked_cards :: proc(cards: ^[dynamic]Card) -> ([dynamic]Card, bool) {
    mouse_pos := rl.GetMousePosition()
    //Reversed because this is the rendering order and we want to select the top one first
    #reverse for card, card_index in cards {
        if mouse_pos.x >= card.position.x &&
           mouse_pos.x <= (card.position.x + CARD_WIDTH) &&
           mouse_pos.y >= card.position.y &&
           mouse_pos.y <= (card.position.y + CARD_HEIGHT) &&
           card.clickable {
            //Copy the clicked slice
            clicked_slice := cards[card_index:len(cards)]
            clicked_slice_copy := make([dynamic]Card, len(clicked_slice))
            copy(clicked_slice_copy[:], clicked_slice[:])

            //Delete from current cards
            remove_range(cards, card_index, len(cards))

            return clicked_slice_copy, true
        }
    }
    return nil, false
}


//Generics here?
take_card_names :: proc(cards: ^[dynamic]string, total: int) -> ([dynamic]string) {
    taken_cards_copy: [dynamic]string
    if len(cards) < total {
        taken_cards_copy = make([dynamic]string, len(cards))
        copy(taken_cards_copy[:], cards[:])
        remove_range(cards, 0, len(cards))
    } else {
        taken_cards_copy = make([dynamic]string, total)
        taken_cards := cards[len(cards) - total:len(cards)]
        copy(taken_cards_copy[:], taken_cards[:])
        remove_range(cards, len(cards) - total, len(cards))
    }

    slice.reverse(taken_cards_copy[:])
    return taken_cards_copy
}
take_cards :: proc(cards: ^[dynamic]Card, total: int) -> ([dynamic]Card) {
    taken_cards_copy: [dynamic]Card
    if len(cards) < total {
        taken_cards_copy = make([dynamic]Card, len(cards))
        copy(taken_cards_copy[:], cards[:])
        remove_range(cards, 0, len(cards))
    } else {
        taken_cards_copy = make([dynamic]Card, total)
        taken_cards := cards[len(cards) - total:len(cards)]
        copy(taken_cards_copy[:], taken_cards[:])
        remove_range(cards, len(cards) - total, len(cards))
    }

    slice.reverse(taken_cards_copy[:])
    return taken_cards_copy
}


get_overlapped_pile :: proc(game_board: ^Game_Board, moving_cards: ^[dynamic]Card) -> (^Pile, bool) {
    if moving_cards == nil || len(moving_cards) == 0 {
        return nil, false
    }

    for i in 0..<len(game_board.tableau) {
        overlapped := check_if_overlapped_pile(&game_board.tableau[i], moving_cards)
        if !overlapped {
            continue
        }

        if len(&game_board.tableau[i].cards) == 0 {
            return &game_board.tableau[i], overlapped
        }

        top_card_pile := top_card(&game_board.tableau[i].cards)
        bottom_moving_card := bottom_card(moving_cards)
        if stackable(top_card_pile, bottom_moving_card) {
            return &game_board.tableau[i], overlapped
        }
    }

    if (len(moving_cards) == 1) {
        for i in 0..<len(game_board.foundation) {
            overlapped := check_if_overlapped_pile(&game_board.foundation[i], moving_cards)
            if !overlapped {
                continue
            }

            bottom_moving_card := bottom_card(moving_cards)
            if len(&game_board.foundation[i].cards) == 0 {
                //Only ace allowed at first
                if bottom_moving_card.rank == 1 {
                    return &game_board.foundation[i], overlapped
                } else {
                    return nil, false
                }
            }

            top_card_pile := top_card(&game_board.foundation[i].cards)

            //Basic stacking game rules!
            if (len(&game_board.foundation[i].cards) == 0 || top_card_pile.color == bottom_moving_card.color) &&
               (top_card_pile.rank + 1) == bottom_moving_card.rank {
                return &game_board.foundation[i], overlapped
            }
        }

        if len(game_board.stock.cards) == 0 {
            // Overlapped stock
            overlapped := check_if_overlapped_pile(&game_board.stock, moving_cards)
            if overlapped {
                return &game_board.stock, overlapped
            }
        }
    }
    return nil, false
}

check_if_overlapped_pile :: proc(pile: ^Pile, moving_cards: ^[dynamic]Card) -> (bool) {
    if moving_cards == nil || len(moving_cards) == 0 {
        return false
    }
    //only check if the bottom card is hoverover over another pile
    bottom_moving_card := bottom_card(moving_cards)

    //Check if hovering pile
    if len(pile.cards) == 0 {
       return bottom_moving_card.position.x >= pile.position.x &&
        bottom_moving_card.position.x <= (pile.position.x + CARD_WIDTH) &&
        bottom_moving_card.position.y >= pile.position.y &&
        bottom_moving_card.position.y <= (pile.position.y + CARD_HEIGHT)
    }

    //Only check the last card (top card) in the pile
    top_card_pile := top_card(&pile.cards)

    if  bottom_moving_card.position.x >= top_card_pile.position.x &&
        bottom_moving_card.position.x <= (top_card_pile.position.x + CARD_WIDTH) &&
        bottom_moving_card.position.y >= top_card_pile.position.y &&
        bottom_moving_card.position.y <= (top_card_pile.position.y + CARD_HEIGHT) {
        return true
    }

    return false
}

set_clickable_cards :: proc(pile: ^Pile) {
    //bottom card always clickable
    top_card(&pile.cards).clickable = true

    //Reverse
    for i := len(pile.cards) - 1; i > 0; i -= 1 {
        if stackable(&pile.cards[i-1], &pile.cards[i]) {
            pile.cards[i-1].clickable = true
        } else {
            //If its not continuous from bottom of stack, break
            break;
        }
    }
}

//Basic stacking game rules here!
stackable :: proc(card: ^Card, card_to_stack: ^Card) -> (bool) {
    return ((card.color == Card_Color.Red && card_to_stack.color == Card_Color.Black) ||
            (card.color == Card_Color.Black && card_to_stack.color == Card_Color.Red)) &&
            card.rank == (card_to_stack.rank + 1)
}

draw_pile :: proc(pile: ^Pile) {
    draw_pile_source := rl.Rectangle {
        x = 0,
        y = 0,
        width = f32(pile.texture.width),
        height = f32(pile.texture.height)
    }

    draw_pile_dest := rl.Rectangle {
        x = pile.position.x,
        y = pile.position.y,
        width = CARD_WIDTH,
        height = CARD_HEIGHT
    }

    rl.DrawTexturePro(
        pile.texture,
        draw_pile_source,
        draw_pile_dest, 0, 0, rl.WHITE
    )
}

draw_cards :: proc(cards: ^[dynamic]Card) {
    if cards == nil || len(cards) == 0 {
        return
    }

    for card in cards {
        draw_card_source := rl.Rectangle {
            x = 0,
            y = 0,
            width = f32(card.texture.width),
            height = f32(card.texture.height)
        }

        draw_card_dest := rl.Rectangle {
            x = card.position.x,
            y = card.position.y,
            width = CARD_WIDTH,
            height = CARD_HEIGHT
        }

        rl.DrawTexturePro(
            card.texture,
            draw_card_source,
            draw_card_dest, 0, 0, rl.WHITE
        )
    }
}

setup_game_board :: proc(game_board: ^Game_Board) {
    //Shuffle the deck
    rand.shuffle(deck_names[:])
    t1 := take_card_names(&deck_names, 1)
    t2 := take_card_names(&deck_names, 2)
    t3 := take_card_names(&deck_names, 3)
    t4 := take_card_names(&deck_names, 4)
    t5 := take_card_names(&deck_names, 5)
    t6 := take_card_names(&deck_names, 6)
    t7 := take_card_names(&deck_names, 7)

    stock := Pile {
       texture = rl.LoadTexture("images/card_back.png"),
       position = rl.Vector2 { 140, 25 },
       stack_direction = rl.Vector2 { 0, 0 }
    }
    add_cards_pile(&stock, &deck_names);
    stock.cards[len(stock.cards) - 1].clickable = true
    game_board.stock = stock

    waste := Pile {
       texture = rl.LoadTexture("images/card_empty.png"),
       position = rl.Vector2 { 230, 25 },
       stack_direction = rl.Vector2 { 30, 0 }
    }
    game_board.waste = waste


    tableau1 := Pile {
       texture = rl.LoadTexture("images/card_empty.png"),
       position = rl.Vector2 { 340, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_cards_pile(&tableau1, &t1);

    tableau2 := Pile {
       texture = rl.LoadTexture("images/card_empty.png"),
       position = rl.Vector2 { 440, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_cards_pile(&tableau2, &t2);

    tableau3 := Pile {
       texture = rl.LoadTexture("images/card_empty.png"),
       position = rl.Vector2 { 540, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_cards_pile(&tableau3, &t3);

    tableau4 := Pile {
       texture = rl.LoadTexture("images/card_empty.png"),
       position = rl.Vector2 { 640, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_cards_pile(&tableau4, &t4);

    tableau5 := Pile {
       texture = rl.LoadTexture("images/card_empty.png"),
       position = rl.Vector2 { 740, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_cards_pile(&tableau5, &t5);

    tableau6 := Pile {
       texture = rl.LoadTexture("images/card_empty.png"),
       position = rl.Vector2 { 840, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_cards_pile(&tableau6, &t6);

    tableau7 := Pile {
       texture = rl.LoadTexture("images/card_empty.png"),
       position = rl.Vector2 { 940, 190 },
       stack_direction = rl.Vector2 { 0, 30 }
    }
    add_cards_pile(&tableau7, &t7);

    set_clickable_cards(&tableau1)
    set_clickable_cards(&tableau2)
    set_clickable_cards(&tableau3)
    set_clickable_cards(&tableau4)
    set_clickable_cards(&tableau5)
    set_clickable_cards(&tableau6)
    set_clickable_cards(&tableau7)

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
       texture = rl.LoadTexture("images/card_empty.png"),
       position = rl.Vector2 { 140, 190 },
       stack_direction = rl.Vector2 { 0, 0 }
    }
    foundation2 := Pile {
       texture = rl.LoadTexture("images/card_empty.png"),
       position = rl.Vector2 { 140, 320 },
       stack_direction = rl.Vector2 { 0, 0 }
    }
    foundation3 := Pile {
       texture = rl.LoadTexture("images/card_empty.png"),
       position = rl.Vector2 { 140, 450 },
       stack_direction = rl.Vector2 { 0, 0 }
    }
    foundation4 := Pile {
       texture = rl.LoadTexture("images/card_empty.png"),
       position = rl.Vector2 { 140, 580 },
       stack_direction = rl.Vector2 { 0, 0 }
    }

    foundation: [dynamic]Pile
    append(&foundation, foundation1)
    append(&foundation, foundation2)
    append(&foundation, foundation3)
    append(&foundation, foundation4)
    game_board.foundation = foundation
}


add_cards_pile :: proc(pile: ^Pile, card_names: ^[dynamic]string) {
    for i in 0..<len(card_names) {
        add_card_pile(pile, card_names[i]);
    }
}

add_card_pile :: proc(pile: ^Pile, texture_name: string) {
    absolute_texture_file := strings.concatenate({"images/", texture_name})

    color: Card_Color
    rank: u8

    clubs := strings.contains(texture_name, "club")
    heart := strings.contains(texture_name, "heart")
    diamond := strings.contains(texture_name, "diamond")
    spade := strings.contains(texture_name, "spade")

    if diamond || heart {
        color = Card_Color.Red
    } else if clubs || spade {
        color = Card_Color.Black
    }

    if strings.contains(texture_name, "_A") {
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
    }

    append(&pile.cards, Card {
        name = absolute_texture_file,
        texture = rl.LoadTexture(strings.clone_to_cstring(absolute_texture_file)),
        position = pile.position + (pile.stack_direction * f32(len(pile.cards))),
        rank = rank,
        color = color
    })
}



module Main exposing (..)

import Browser
import Html exposing (Html, text, div, h1, img)
import Html.Attributes exposing (src)
import Html.Events
import Json.Decode as Decode
import Json.Encode as Encode
import JoyDivision


---- MODEL ----


type alias Model =
    {state : State, fft : List Fft, scroll : Float, buffer : Float}

type alias Fft = List Float

type State =
    Paused
    | Playing

stateToString state =
    case state of
        Paused -> "paused"
        Playing -> "playing"

keyframes =
    { from = {drums = 0, melody = 0.8}
    , over = {drums = 0.8, melody = 1}
    , to = to
    }

to : Frame
to = {drums = 0.8, melody = 0}

-- [generator-start]
type alias Frame = {drums : Float, melody: Float}

-- [generator-generated-start] -- DO NOT MODIFY or remove this line
decodeFrame =
   Decode.map2
      Frame
         ( Decode.field "drums" Decode.float )
         ( Decode.field "melody" Decode.float )

encodeFrame a =
   Encode.object
      [ ("drums", Encode.float a.drums)
      , ("melody", Encode.float a.melody)
      ] 
-- [generator-end]

interpolate : Float -> Frame
interpolate step =
    let
        fn start end position =
            start + ((end - start) * position)
    in
        { drums =
            if step > 0.5
                then fn keyframes.over.drums keyframes.to.drums (step * 2 - 1)
                else fn keyframes.from.drums keyframes.over.drums (step * 2)
        , melody =
            if step > 0.5
                then fn keyframes.over.melody keyframes.to.melody (step * 2 - 1)
                else fn keyframes.from.melody keyframes.over.melody (step * 2)
        }

initFft = List.repeat 600 (List.repeat 600 -200)

init : ( Model, Cmd Msg )
init =
    ( {state = Paused, fft = initFft, scroll = 0, buffer = 0}, Cmd.none )
---- UPDATE ----


type Msg
    = NoOp
    | Play
    | Stop
    | FftReceived (List Float)
    | Scrolled Float
    | BufferLoad Float



update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )
        Play ->
            ( {model | state = Playing}, Cmd.none )
        Stop ->
            ( {model | state = Paused}, Cmd.none )
        Scrolled pct ->
            ( {model | scroll = pct}, Cmd.none )
        FftReceived fft ->
            ( {model | fft = fft :: model.fft |> List.take 150}, Cmd.none )
        BufferLoad percent ->
            ( {model | buffer = percent}, Cmd.none )


quote = Html.p [Html.Attributes.class "quote"] [
    Html.text "I think any time somebody considers what they want from"
    , Html.span [Html.Attributes.class "ellipsis"] [Html.text "[...]"]
    , Html.text "an economy in a situation where technology is getting better and better is"
    , Html.span [Html.Attributes.class "ellipsis"] [Html.text "[...]"]
    , Html.text "the economy to"
    , Html.span [Html.Attributes.class "ellipsis"] [Html.text "[...]"]
    , Html.text "be about subjective values."
    , Html.span [Html.Attributes.class "ellipsis"] [Html.text "[...]"]
    , Html.text "That's a signal that we are creating technologies and an economy that's really "
    , Html.span [Html.Attributes.class "nowrap"] [Html.text "serving us."]
    ]

-- Jaron Lanier, Making Sense Podcast #135, minute 11

---- VIEW ----

renderStyles {fft} =
    let
        selector index = "path:nth-child(" ++ (String.fromInt index) ++ "n)"
        prop1 val = "transform: rotate(" ++ (String.fromFloat (val / 100)) ++ "deg)"
        renderRule1 index val =  selector index ++ "{" ++ prop2 val ++ "}"
        prop2 val = "stroke-dashoffset: " ++ (String.fromFloat val)
        -- renderRule2 index val = "path:nth-child(" ++ (String.fromInt index) ++ "n) { ++ "}"
        rules =
            fft
            |> List.indexedMap renderRule1
            |> String.join "\n"
--         rules2 =
--             fft
--             |> List.indexedMap renderRule2
--             |> String.join "\n"
    in
        Html.node "style" [] [Html.text (rules)]

visualizer : Fft -> Html Msg
visualizer fft =
    let
        height = Html.Attributes.style "height" "200px"
        bg = Html.Attributes.style "background-color" "red"
        display = Html.Attributes.style "display" "flex"
        alignBottom = Html.Attributes.style "align-items" "flex-end"
        renderBar val =
            let
                width = Html.Attributes.style "width" ((String.fromFloat <| 100 / (List.length fft |> toFloat)) ++ "%")
                bg_ = Html.Attributes.style "background-color" "white"
                offset = Html.Attributes.style "transform" ("translateY(" ++ String.fromFloat val ++ "px)")
            in
                Html.div
                    [height, offset, width, bg_]
                    []
    in
        fft
        |> List.map renderBar
        |> Html.div [height, display, alignBottom]


scrollObserver =
    Html.node "scroll-observer" [onScroll, Html.Attributes.style "display" "none"] []
items = ["/painting-1.jpg", "/painting-2.jpg", "/painting-3.jpg"]
imgs =
    items
    |> List.map (\src -> Html.node "intense-image" [Html.Attributes.class "artwork"] [ Html.img [Html.Attributes.src src] []])
    |> Html.div [Html.Attributes.class "paintings"]

viz : List Fft -> Html JoyDivision.Msg
viz fft =
    let
        joyModel =
            fft
            |> JoyDivision.fromList
    in
    JoyDivision.view joyModel

player model =
    let
        frame = interpolate model.scroll
    in
        Html.section [Html.Attributes.class "player"][
            playButton model
            , Html.node "factory-beat-player"
                [ onFft
                , onBufferLoad
                , Html.Attributes.attribute "state" (stateToString model.state)
                , Html.Attributes.attribute "levels" (encodeFrame frame |> Encode.encode 4)
                ] []
        ]



onFft =
    Html.Events.on "fft" decodeFft

onBufferLoad =
    Html.Events.on "bufferloaded" (Decode.field "detail" Decode.float |> Decode.map BufferLoad)

decodeFft : Decode.Decoder Msg
decodeFft =
    Decode.field "detail" (Decode.list Decode.float)
    |> Decode.map FftReceived

onScroll =
    Html.Events.on "scrollPct" decodeScroll

decodeScroll : Decode.Decoder Msg
decodeScroll =
    Decode.field "detail" (Decode.float)
    |> Decode.map Scrolled

introText =
    Html.p [Html.Attributes.class "intro-text"]
        [ Html.text "My name is Jan. I am a software/design/music crossover entrepreneur. "
        , Html.text "This is an interactive music installation handcrafted just for you. Yes. You. "
        , Html.text "The themes of the artist residency spoke to me right away as I am passionate about technology and its implications for how we think, live and love. "
        , Html.text "Also: a quote heavy with meaning and projects in the field of technology, music and some art."
        ]

intro model = Html.section [Html.Attributes.class "intro-section"] [
              Html.div [Html.Attributes.class "greeting"][text "Hallo!"]
            , introText
            , player model
        ]

quoteSection =
        Html.section [Html.Attributes.class "quote-section"] [
              quote
            , Html.p [Html.Attributes.class "quote-source"] [
                Html.text "Jaron Lanier, Philosopher, Artist, Technologist"
            ]
        ]


paintings model =
    Html.section [Html.Attributes.class "painting-section"] <| [
          Html.h2 [] [Html.text "Paintings"]
        , Html.p [] [Html.text "When I'm not coding, I do paintings or make electronic music. These are some paintings. Click To Enlarge."]
        , (if model.buffer == 1 then imgs else Html.text "loading...")
        ]

projects =
    Html.section [Html.Attributes.class "projects-section"] [
              Html.h2 [] [Html.text "Software"]
            , Html.div [Html.Attributes.class "projects-content"] [
                softwareExperience
            ]
            , Html.div [Html.Attributes.class "projects-content"] [
                maffText, maffImg
            ]
        ]

musicSection =
    Html.section [Html.Attributes.class "music-section"] [
              Html.h2 [] [Html.text "Music"]
       , Html.p [] [
         Html.text "The soundtrack on this very application was produced by me on an MPC Live. "
       , Html.text "Good music is one of the important things in my life. "
       , Html.text "In the smalltown I grew up there are no electronic music events. I kickstarted a series of house music events featuring local DJs. We had ~40 paying guests per night."
       , Html.text "The next event was crashed by corona."
       , Html.text "I played DJ gigs on Art Exhibitions in Heidelberg and bars in Lisbon, in front of 1000 people in my smalltown and on chillout floors of druggy underground raves. "
       , Html.text "My musical network spans across Berlin, Mainz, Heidelberg, Lisbon and Amsterdam."
       ]
    ]

beyondSection =
    Html.section [Html.Attributes.class "beyond-section"] [
              Html.h2 [] [Html.text "Beyond all that"]
       , Html.text "By now you should know what I am passionate about and capable of. "
       , Html.text "I am super keen to get out of my comfort zone, to experiment with VR/AR as well as work with instrumentalists and singers. "
       , Html.text "I want to enable people and I am happy to bring my resources and network to the table."
       , Html.h2 [Html.Attributes.class "bye"] [Html.i [] [Html.text "See ya! :)"]]

        ]

maffImg =
        Html.img [Html.Attributes.src "/maff.png", Html.Attributes.class "maff-picture"] []

maffText =
    Html.p [Html.Attributes.class "maff"] [
         Html.text "You were asking for chatbots. Nice. "
       , Html.a [ Html.Attributes.href "https://github.com/FranzSkuffka/maff"] [Html.text "Maff"]
       , Html.text " is a Telegram bot that helps you transcribe photos of hand-written mathematical terms into LaTeX expression, reducing the need for scientists to learn LaTeX syntax. "
       , Html.text "Maff uses computer vision technology to do its job. I wrote it in on a misty sunday afternoon."
   ]

view : Model -> Html Msg
view model =
    Html.article [] <|
        -- intro
        [ viz model.fft |> Html.map (always NoOp)
        , scrollObserver
        , h1 [Html.Attributes.class "title"] [ text "Jan Wirth - Artist Residency application"]
        , intro model
        , quoteSection
        -- what I do
        , paintings model
        , projects
        , musicSection
        , beyondSection

        -- scalab, music, arts
        -- what I did
        -- outro
        ]

softwareExperience =
    Html.p [Html.Attributes.class "scalab-text"] [
            Html.text "I am the co-founder of "
            , Html.a [Html.Attributes.href "https://scalab.app"] [Html.text "scalab.app"]
            , Html.text ". We are working on technology that makes complex web app development accessible to more humans. "
            , Html.text "Scalab is an open-source 'low-code' environment. "
            , Html.text "You can design without code and evolve your work into a full web application. "
            , Html.text "However, unlike other solutions, scalab is compatible with traditional, code-driven development workflows. "
            , Html.text "That means everyone in a team that knows how to use tools like Microsoft Powerpoint can participate in the creation of the thing that gets shipped to the user. "
            , Html.text "I met my co-founder David Beesley through "
            
            , Html.a [Html.Attributes.href "https://joinef.com"] [Html.text "Entrepreneur First"]
            , Html.text ", 'the world’s leading talent investor'."
            , Html.p [] [
                Html.text "Before Scalab I did work for "
              , Html.a [Html.Attributes.href "https://mercedes-benz.io"] [Html.text "Mercedes-Benz.io"]
              , Html.text " taking responsibility for the success of both customer-facing and internal tools. "
              -- , Html.text "I fulfilled this responsibility in Stuttgart, Berlin, Lisbon and Singapore. "
              -- , Html.text "I am grateful for this rich cultural and professional experience."
            ]
        ]

playButton : Model -> Html.Html Msg
playButton {state, buffer} =
    case state of
        Paused ->
            let
                isLoaded = buffer == 1
                label = if isLoaded then "Play"
                        else "Loading " ++ (buffer * 100 |> round |> String.fromInt) ++ "%"
            in
                Html.button
                    (if isLoaded
                    then [Html.Events.onClick Play, Html.Attributes.class "player-button"]
                    else [Html.Attributes.class "player-button"]
                    )
                    [Html.text label]
        Playing ->
            Html.button
                [Html.Events.onClick Stop, Html.Attributes.class "player-button"]
                [Html.text "stopstop"]

---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }


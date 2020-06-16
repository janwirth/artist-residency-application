module JoyDivision exposing (view, fromList, Msg)

import Array exposing (Array)
import Browser
import Canvas exposing (..)
import Canvas.Settings exposing (..)
import Canvas.Settings.Line exposing (..)
import Color exposing (Color)
import Grid
import Html exposing (..)
import Html.Attributes exposing (style)
import Random
import Time exposing (Posix)


--main : Program Float Model Msg
--main =
--    Browser.element { init = init, update = update, subscriptions = subscriptions, view = view }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


h : number
h =
    1500


w : number
w =
    2000


paddingY : number
paddingY =
    300


stepX =
    150


stepY =
    10


cols =
    (w * 2) // stepX


rows =
    (h - paddingY * 2) // stepY


cells =
    rows * cols


type alias Points =
    Array { point : ( Float, Float ), random : Float }


type alias Model =
    { count : Int
    , points : Points
    }

fromList : List (List Float) -> Model
fromList fft =
    let
        randomYs = fft
            |> List.map (List.take cols >> List.map ((*) 0.99))
            |> List.concatMap identity
        pointFromIndexAndRandom i r =
            { point =
                indexToCoords i
                    |> Tuple.mapBoth toFloat toFloat
                    |> coordsToPx
                    |> moveAround (r / 30)

            , random = 0
            }

        points =
            Array.fromList randomYs
                |> Array.indexedMap pointFromIndexAndRandom
    in
    { count = 0
    , points = points
    }

type Msg
    = AnimationFrame Posix


coordsToIndex x y =
    -- If x is out of the grid, don't give a valid index
    if x < cols && y < rows then
        y * cols + x

    else
        -1


indexToCoords i =
    ( remainderBy cols i
    , i // cols
    )


coordsToPx ( x, y ) =
    ( (x - 1) * stepX + stepX / 2
    , y * stepY + stepY / 2 + paddingY * 1.3
    )


moveAround r ( x, y ) =
    let
        distanceToCenter =
            abs ((x - w / 2) / 3)
            

        maxVariance =
            150

        p =
            ((w * 2 - 100) / 2) / maxVariance

        variance =
            max (-distanceToCenter / p + maxVariance) 0

        random =
            r * variance / 2 * -1
    in
    ( x, y + random )

 
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AnimationFrame delta ->
            ( { model | count = model.count + 1 }
            , Cmd.none
            )



view : Model -> Html Msg
view model =
    Canvas.toHtml
        ( w, h )
        []
        (clearScreen ::
        (Grid.fold2d { cols = cols, rows = rows } (drawLines model.points) ( Array.empty, Array.empty )
                    |> Tuple.second
                    |> Array.toList
               )
        )



clearScreen =
    clear (0, 0) w h


drawLines : Points -> ( Int, Int ) -> ( Array PathSegment, Array Renderable ) -> ( Array PathSegment, Array Renderable )
drawLines points ( x, y ) ( currentLine, lines ) =
    let
        { point } =
            Array.get (coordsToIndex x y) points
                -- This shouldn't happen as we should always be in the matrix
                -- bounds
                |> Maybe.withDefault { point = ( 0, 0 ), random = 0 }

        ( px, py ) =
            point

        drawPoint =
            if x == 0 then
                moveTo ( px, py )

            else
                let
                    nextPoint =
                        points
                            |> Array.get (coordsToIndex (x + 1) y)
                            |> Maybe.withDefault { point = ( px + stepX, py ), random = 0 }

                    ( nx, ny ) =
                        nextPoint.point

                    ( xc, yc ) =
                        ( (px + nx) / 2
                        , (py + ny) / 2
                        )
                in
                quadraticCurveTo ( px, py ) ( xc, yc )
    in
    if x == cols - 1 then
        let
            a = 0.4
            newLine =
                shapes
                    [ lineWidth 1.5
                    -- , fill bgColor
                    , stroke <| Color.rgba 96 0 117 a
                    ]
                    [ path ( 0, 0 )
                        -- We add the moveTo above to the line, so this won't matter
                        (Array.push drawPoint currentLine
                            |> Array.toList
                        )
                    ]
        in
        ( Array.empty, Array.push newLine lines )

    else
        ( Array.push drawPoint currentLine, lines )

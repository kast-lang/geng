use (import "../../src/_lib.ks").*;

const Game = newtype {};

@eval (impl Game as geng.App = {
    .init = () -> Game => {},
    .update = (self :: &mut Game, delta_time :: Float32) => (),
    .handle_event = (self :: &mut Game, event :: geng.Event) => (),
    .draw = (self :: &mut Game) => (),
});

geng.run[Game](
    .title = "Geng Example",
    .vsync = true,
);

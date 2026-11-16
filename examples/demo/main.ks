use (import "../../src/_lib.ks").*;

const Game = newtype {
    .white_texture :: ugli.Texture,
    .camera :: geng.Camera,
};

@eval (impl Game as geng.App = {
    .init = () -> Game => {
        .white_texture = ugli.Texture.new_with(
            { 8, 8 },
            { x, y } => { Int32_to_Float32(x) / 7, Int32_to_Float32(y) / 7, 1, 1 },
            :Nearest,
        ),
        .camera = {
            .position = { 0, 0, 0 },
            .distance = 4,
            .rotation = Angle.from_degrees(90),
            .attack = Angle.from_degrees(90),
            .fov = :Vertical Angle.from_degrees(90),
        },
    },
    .update = (self :: &mut Game, delta_time :: Float32) => (),
    .handle_event = (self :: &mut Game, event :: geng.Event) => (),
    .draw = (self :: &mut Game) => (
        ugli.clear({ 0, 0, 0, 1 });
        with geng.CameraUniforms.Ctx = geng.CameraUniforms.init(
            self^.camera,
            .framebuffer_size = geng.get_window_size(),
        );
        geng.draw_quad(
            .pos = { 0, 0 },
            .half_size = { 1, 1 },
            .texture = &self^.white_texture,
        );
    ),
});

geng.run[Game](
    .title = "Geng Example",
    .vsync = true,
);

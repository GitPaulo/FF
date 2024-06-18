return {
    name = 'Samurai2',
    traits = {health = 100, speed = 180, stamina = 100},
    hitboxes = {
        light = {width = 90, height = 20, recovery = 0.1, damage = 7, duration = 0.5},
        medium = {width = 90, height = 90, recovery = 0.4, damage = 12, duration = 0.7},
        heavy = {width = 90, height = 90, recovery = 0.8, damage = 25, duration = 1.2}
    },
    spriteConfig = {
        idle = {'assets/fighters/Samurai2/Idle.png', 4},
        run = {'assets/fighters/Samurai2/Run.png', 8},
        jump = {'assets/fighters/Samurai2/Jump.png', 2},
        light = {'assets/fighters/Samurai2/Attack1.png', 4},
        medium = {'assets/fighters/Samurai2/Attack2.png', 4},
        heavy = {'assets/fighters/Samurai2/Attack2.png', 4},
        hit = {'assets/fighters/Samurai2/TakeHit.png', 3},
        death = {'assets/fighters/Samurai2/Death.png', 7}
    },
    soundFXConfig = {
        light = 'assets/fighters/Samurai2/Attack1.wav',
        medium = 'assets/fighters/Samurai2/Attack1.wav',
        heavy = 'assets/fighters/Samurai2/Attack1.wav',
        hit = 'assets/fighters/Samurai2/Hit.mp3',
        block = 'assets/fighters/Samurai2/Block.wav',
        jump = 'assets/fighters/Samurai2/Jump.mp3'
    }
}

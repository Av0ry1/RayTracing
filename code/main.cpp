#include <SFML\Graphics.hpp>
#include <random>
#include <math.h>

int main()
{
    // CONSTANTS
    const int W = 1920, H = 1080; // window resolution
    const int MAX_DEPTH = 16; // max ray reflection count
    const int MAX_DISTANCE = 100000; // render distance
    const int SAMPLE_COUNT = 8; // sample per frame count

    const float SPEED = 0.2f;
    const float SENSITIVITY = 1.2f;

    // CAMERA VARIABLES
    sf::Vector3f pos(0.0, 0.0, 1.0); // camera position
    sf::Vector2f angle(0.0, 0.0); // camera angle


    // CONTROLS
    bool controls[6] = { false, false, false, false, false, false };


    // OTHER VARIABLES
    int frames;


    // RENDER OBJECTS
    sf::RenderWindow window(sf::VideoMode(W, H), "RayTracing!", sf::Style::Fullscreen);
    window.setFramerateLimit(60);
    window.setMouseCursorVisible(false);

    sf::RenderTexture renderTexture;
    renderTexture.create(W, H);
    sf::Sprite renderTextureSprite = sf::Sprite(renderTexture.getTexture());

    // OTHER SFML OBJECTS
    sf::Clock clock;

    // LOAD SHADER
    sf::FileInputStream shaderFile;
    shaderFile.open("code/shader.frag");
    sf::Shader shader;
    shader.loadFromStream(shaderFile, sf::Shader::Fragment);

    // RANDOM
    std::random_device rd;
	std::mt19937 e2(rd());
	std::uniform_real_distribution<> dist(0.0f, 1.0f);

    // SET UNIFORMS
    shader.setUniform("RESOLUTION", sf::Vector2f(W, H));
    shader.setUniform("MAX_DEPTH", MAX_DEPTH);
    shader.setUniform("MAX_DISTANCE", MAX_DISTANCE);
    shader.setUniform("SAMPLE_COUNT", SAMPLE_COUNT);

    while (window.isOpen())
    {
        sf::Event event;
        while (window.pollEvent(event))
        {
            if (event.type == sf::Event::Closed)
            {
                window.close();
            }

            else if (event.type == sf::Event::MouseMoved)
            {
				angle.x += ((float)(event.mouseMove.x - W / 2) / W) * SENSITIVITY;
				angle.y -= ((float)(event.mouseMove.y - H / 2) / H) * SENSITIVITY;
				sf::Mouse::setPosition(sf::Vector2i(W / 2, H / 2), window);
                if (event.mouseMove.x != W / 2 || event.mouseMove.y != H / 2) frames = 1;
            }

            else if (event.type == sf::Event::KeyPressed)
			{
				if (event.key.code == sf::Keyboard::W) controls[0] = true;
				else if (event.key.code == sf::Keyboard::A) controls[1] = true;
				else if (event.key.code == sf::Keyboard::S) controls[2] = true;
				else if (event.key.code == sf::Keyboard::D) controls[3] = true;
				else if (event.key.code == sf::Keyboard::Space) controls[4] = true;
				else if (event.key.code == sf::Keyboard::LControl) controls[5] = true;
			}

			else if (event.type == sf::Event::KeyReleased)
			{
				if (event.key.code == sf::Keyboard::W) controls[0] = false;
				else if (event.key.code == sf::Keyboard::A) controls[1] = false;
				else if (event.key.code == sf::Keyboard::S) controls[2] = false;
				else if (event.key.code == sf::Keyboard::D) controls[3] = false;
				else if (event.key.code == sf::Keyboard::Space) controls[4] = false;
				else if (event.key.code == sf::Keyboard::LControl) controls[5] = false;
			}
        }


        for (int i = 0; i < 6; i++)
        {
            if (controls[i])
            {
                frames = 1;
                break;
            }
        }


        // MOVE CAMERA
        sf::Vector3f dir(0.0, 0.0, 0.0);
        sf::Vector3f dirTemp;

        if (controls[0]) dir += sf::Vector3f(1.0f, 0.0f, 0.0f); 
        if (controls[2]) dir += sf::Vector3f(-1.0f, 0.0f, 0.0f); 
        if (controls[3]) dir += sf::Vector3f(0.0f, 1.0f, 0.0f); 
        if (controls[1]) dir += sf::Vector3f(0.0f, -1.0f, 0.0f); 
        if (controls[4]) dir += sf::Vector3f(0.0f, 0.0f, 1.0f);
		if (controls[5]) dir += sf::Vector3f(0.0f, 0.0f, -1.0f);

        dirTemp.z = dir.z * cos(-angle.y) - dir.x * sin(-angle.y);
        dirTemp.x = dir.z * sin(-angle.y) + dir.x * cos(-angle.y);
        dirTemp.y = dir.y;
        dir.x = dirTemp.x * cos(angle.x) - dirTemp.y * sin(angle.x);
        dir.y = dirTemp.x * sin(angle.x) + dirTemp.y * cos(angle.x);
        dir.z = dirTemp.z;
        pos += dir * SPEED;

        // SET UNIFORMS
        shader.setUniform("position", pos);
        shader.setUniform("angle", angle);

        shader.setUniform("seed1", sf::Vector2f((float)dist(e2), (float)dist(e2)) * 999.0f);
	    shader.setUniform("seed2", sf::Vector2f((float)dist(e2), (float)dist(e2)) * 999.0f);

        shader.setUniform("sampleCount", frames);
        shader.setUniform("sample", renderTexture.getTexture());


        // DRAW
        window.clear();

        renderTexture.draw(renderTextureSprite, &shader);
        window.draw(renderTextureSprite);

        window.display();
        frames++;
    }

    return 0;
}
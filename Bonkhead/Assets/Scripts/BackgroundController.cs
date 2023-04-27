using UnityEngine;

public class BackgroundController : MonoBehaviour
{
    [SerializeField] private Vector2 speedMovement; // Velocidad de movimiento del fondo

    private Rigidbody2D rigidbodyPlayer; // Componente Rigidbody2D del jugador
    private Renderer backgroundRenderer; // Componente Renderer del fondo

    private Vector2 offset; // Offset para mover el fondo

    // Esta función se llama cuando se inicia el juego
    void Start()
    {
        // Se obtiene el componente Renderer del fondo
        backgroundRenderer = GetComponent<Renderer>();

        // Se busca y se obtiene el componente Rigidbody2D del jugador
        rigidbodyPlayer = GameObject.FindGameObjectWithTag("Player").GetComponent<Rigidbody2D>();
    }

    // Esta función se llama una vez por cuadro y se utiliza para actualizar la posición del fondo
    void Update()
    {
        // Se calcula el offset para mover el fondo en función de la velocidad horizontal del jugador, la velocidad de movimiento del fondo y el tiempo transcurrido desde el último cuadro
        offset = (rigidbodyPlayer.velocity.x * 0.1f) * speedMovement * Time.deltaTime;

        // Se aplica el offset al material del sprite del fondo para moverlo
        backgroundRenderer.material.mainTextureOffset += offset;
    }
}


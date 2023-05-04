using UnityEngine;

public class EnemyController_3 : MonoBehaviour
{
    public LayerMask groundLayer; // Capa del suelo para la detección de colisiones
    public Transform groundCheck; // Punto de comprobación para detectar si el personaje está en el suelo
    public Transform player; // Referencia al objeto del jugador
    
    private Rigidbody2D rb; // Referencia al componente Rigidbody2D del enemigo
    private bool CanSeePlayer; // Indica si el enemigo puede ver al jugador
    private float moveSpeed; // Velocidad de movimiento del enemigo
    private float moveDir; // Dirección de movimiento del enemigo

    void Start()
    {
        rb = GetComponent<Rigidbody2D>(); // Obtiene la referencia al componente Rigidbody2D del enemigo

        CanSeePlayer = false; // Indica que el enemigo no esta viendo al jugador
        moveSpeed = 5f; // Inicializa la velocidad de movimiento del enemigo
        moveDir = 0; // Inicializa la dirección de movimiento del enemigo
    }

    void Update()
    {
        if (CanSeePlayer) // Si el enemigo puede ver al jugador
        {
            if (transform.position.x < player.position.x) // Si el enemigo está a la izquierda del jugador
            {
                moveDir = 1; // Establece la dirección de movimiento hacia la derecha
                rb.velocity = new Vector2(moveDir * moveSpeed, rb.velocity.y); // Establece la velocidad de movimiento hacia la derecha
            }
            else if (transform.position.x > player.position.x) // Si el enemigo está a la derecha del jugador
            {
                moveDir = -1; // Establece la dirección de movimiento hacia la izquierda
                rb.velocity = new Vector2(moveDir * moveSpeed, rb.velocity.y); // Establece la velocidad de movimiento hacia la izquierda
            }
        }
    }

    void OnTriggerEnter2D(Collider2D collision)
    {
        if (collision.CompareTag("Player")) // Si el objeto que entra en contacto es el jugador
        {
            CanSeePlayer = true; // El enemigo puede ver al jugador
        }
    }

    void OnTriggerExit2D(Collider2D collision)
    {
        if (collision.CompareTag("Player")) // Si el objeto que sale del contacto es el jugador
        {
            CanSeePlayer = false; // El enemigo no puede ver al jugador
        }
    }
}

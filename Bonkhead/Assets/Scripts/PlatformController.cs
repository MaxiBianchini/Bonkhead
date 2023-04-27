using UnityEngine;

public class PlatformController : MonoBehaviour
{
    private PlatformEffector2D platformEffector; // Componente PlatformEffector2D de la plataforma
    private bool isOnFloatingGround; // Indica si el jugador está en una superficie flotante

    private void Start()
    {
        // Obtener el componente PlatformEffector2D de la plataforma
        platformEffector = GetComponent<PlatformEffector2D>();
    }

    private void Update()
    {
        // Si el jugador presiona la tecla "abajo" y "espacio" y está sobre una superficie flotante, girar la plataforma 180 grados
        if (Input.GetKey(KeyCode.DownArrow) && Input.GetKey(KeyCode.Space) && isOnFloatingGround)
        {
            platformEffector.rotationalOffset = 180;
        }
    }

    private void OnCollisionExit2D(Collision2D collision)
    {
        // Si el objeto que sale de la colisión es el jugador, reiniciar el ángulo de la plataforma y establecer que no está en una superficie flotante
        if (collision.gameObject.CompareTag("Player"))
        {
            platformEffector.rotationalOffset = 0;
            isOnFloatingGround = false;
        }
    }

    private void OnCollisionEnter2D(Collision2D collision)
    {
        // Si el objeto que entra en la colisión es el jugador, establecer que está en una superficie flotante
        if (collision.gameObject.CompareTag("Player"))
        {
            isOnFloatingGround = true;
        }
    }
}


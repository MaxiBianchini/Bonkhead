using UnityEngine;

public class PlatformController : MonoBehaviour
{
    private PlatformEffector2D platformEffector; // Componente PlatformEffector2D de la plataforma
    private bool isOnFloatingGround; // Indica si el jugador est� en una superficie flotante

    private void Start()
    {
        // Obtener el componente PlatformEffector2D de la plataforma
        platformEffector = GetComponent<PlatformEffector2D>();
    }

    private void Update()
    {
        // Si el jugador presiona la tecla "abajo" y "espacio" y est� sobre una superficie flotante, girar la plataforma 180 grados
        if (Input.GetKey(KeyCode.DownArrow) && Input.GetKey(KeyCode.Space) && isOnFloatingGround)
        {
            platformEffector.rotationalOffset = 180;
        }
    }

    private void OnCollisionExit2D(Collision2D collision)
    {
        // Si el objeto que sale de la colisi�n es el jugador, reiniciar el �ngulo de la plataforma y establecer que no est� en una superficie flotante
        if (collision.gameObject.CompareTag("Player"))
        {
            platformEffector.rotationalOffset = 0;
            isOnFloatingGround = false;
        }
    }

    private void OnCollisionEnter2D(Collision2D collision)
    {
        // Si el objeto que entra en la colisi�n es el jugador, establecer que est� en una superficie flotante
        if (collision.gameObject.CompareTag("Player"))
        {
            isOnFloatingGround = true;
        }
    }
}


using UnityEngine;

public class GroundCheck : MonoBehaviour
{
    public bool isOnGround; // Indica si el personaje est� tocando el suelo
    public bool isOnFloatingGround; // Indica si el personaje est� tocando una plataforma flotante

    void OnTriggerEnter2D(Collider2D collision)
    { 
        // Si el jugador colisiona con una plataforma "Ground":
        if (collision.gameObject.CompareTag("Ground"))
        {
            isOnGround = true;
        }

        // Si el jugador colisiona con una plataforma "Floating Ground":
        if (collision.gameObject.CompareTag("Floating Ground"))
        {
            isOnFloatingGround = true;
        }
    }

    void OnTriggerExit2D(Collider2D collision)
    {

        // Si el jugador deja de colisionar con una plataforma "Ground":
        if (collision.gameObject.CompareTag("Ground"))
        {
            isOnGround = false;
        }

        // Si el jugador deja de colisionar con una plataforma "Floating Ground":
        if (collision.gameObject.CompareTag("Floating Ground"))
        {
            isOnFloatingGround = false;
        }
    }

    public bool CheckIsOnGround()
    {
        return isOnGround;
    }

    public bool CheckIsOnFloatingGround()
    {
        return isOnFloatingGround;
    }

}
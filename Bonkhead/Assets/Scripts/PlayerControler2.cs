using UnityEngine;

public class PlayerControler2 : MonoBehaviour
{
    // Variables de movimiento
    public float moveSpeed = 5f;
    private Vector2 moveDirection = Vector2.zero;

    // Componente CharacterController
    private CharacterController characterController;

    // Método que se llama al inicio
    private void Start()
    {
        // Obtener el componente CharacterController
        characterController = GetComponent<CharacterController>();
    }

    // Método que se llama cada frame
    private void Update()
    {
        // Obtener el input del jugador
        moveDirection = new Vector2(Input.GetAxis("Horizontal"), Input.GetAxis("Vertical"));

        // Normalizar la dirección de movimiento
        if (moveDirection.magnitude > 1)
        {
            moveDirection = moveDirection.normalized;
        }
    }

    // Método que se llama cada fixed frame
    private void FixedUpdate()
    {
        // Mover el personaje
        characterController.Move(moveDirection * moveSpeed * Time.fixedDeltaTime);
    }

}

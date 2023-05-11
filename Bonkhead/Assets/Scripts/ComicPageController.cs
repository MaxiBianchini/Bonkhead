using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ComicPageController : MonoBehaviour
{
    public float ID;

    public float amplitude = 0.5f;  // Amplitud del movimiento de levitación
    public float frequency = 1f;   // Frecuencia del movimiento de levitación

    private Vector3 initialPosition;  // Posición inicial del objeto

    private void Start()
    {
        // Guardar la posición inicial del objeto
        initialPosition = transform.position;
    }

    private void Update()
    {
        // Calcular la posición vertical de levitación
        float yPosition = initialPosition.y + Mathf.Sin(Time.time * frequency) * amplitude;

        // Actualizar la posición del objeto con la posición vertical calculada
        transform.position = new Vector3(transform.position.x, yPosition, transform.position.z);
    }

    void OnTriggerEnter2D(Collider2D collision)
    {
        // Si el objeto que ha colisionado con la bala tiene la etiqueta "Player":
        if (collision.gameObject.CompareTag("Player"))
        {
            // Destruye la bala.
            Destroy(gameObject);
            // Llama al método "ActivateNewPower(ID)" del componente "CharacterController" adjunto al objeto que ha colisionado con la pagina del comic (el jugador).
            collision.GetComponent<CharacterController>().ActivateNewPower(ID);
        }
    }
}

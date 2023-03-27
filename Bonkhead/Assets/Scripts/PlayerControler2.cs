using UnityEngine;

public class PlayerControler2 : MonoBehaviour
{
    public float moveSpeed = 5f;   // Velocidad de movimiento del personaje
    public float jumpForce = 10f;  // Fuerza de salto del personaje

    private Rigidbody2D rb;
    public bool isGrounded = false;
    private bool facingRight = true;

    public GameObject groundCast2D;

    void Start()
    {
        rb = GetComponent<Rigidbody2D>();
    }

    void FixedUpdate()
    {
        // Movimiento horizontal
        float moveX = Input.GetAxisRaw("Horizontal");
        rb.velocity = new Vector2(moveX * moveSpeed, rb.velocity.y);

        // Comprobar si el personaje está en el suelo
        RaycastHit2D hit = Physics2D.Raycast(groundCast2D.transform.position, Vector2.down, 1f);
        if (hit.collider == null)
        {
            if (hit.transform.tag == "Ground")
            {
                isGrounded = true;
            }
            else
            {
                isGrounded = false;
            }
        }
       


        if (moveX > 0.1f && !facingRight)
        {
            flip();
        }

        if (moveX < -0.1f && facingRight)
        {
            flip();
        }


        // Salto
        if (Input.GetButtonDown("Jump") && isGrounded)
        {
            rb.AddForce(new Vector2(0f, jumpForce), ForceMode2D.Impulse);
            isGrounded = false;
        }
    }

    void flip()
    {
        facingRight = !facingRight;
        Vector3 scale = transform.localScale;
        scale.x *= -1;
        transform.localScale = scale;
    }
}

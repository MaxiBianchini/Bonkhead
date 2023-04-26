using UnityEngine;

public class EnemyController_3 : MonoBehaviour
{
    public LayerMask groundLayer;

    public Transform groundCheck;
    private Rigidbody2D rb;

    private bool isGrounded;
    private bool seePlayer;

    private float moveSpeed;
    private float moveDir;

    void Start()
    {
        rb = GetComponent<Rigidbody2D>();

        isGrounded = false;
        seePlayer = false;

        moveSpeed = 5f;
        moveDir = 0;
    }

    void Update()
    {
        isGrounded = Physics2D.OverlapCircle(groundCheck.position, 0.1f, groundLayer);

        if (CanSeePlayerOnRight())
        {
           moveDir = 1;
           seePlayer = true;
        }
        else if (CanSeePlayerOnLeft())
        {
           moveDir = -1;
           seePlayer = true;
        }
        else 
        {  
           moveDir = 0;
           seePlayer = false;
        }
    }

    void FixedUpdate()
    {
        if (isGrounded && seePlayer)
        {
            rb.velocity = new Vector2(moveDir * moveSpeed, rb.velocity.y);
        }
    }

    bool CanSeePlayerOnRight()
    {
        RaycastHit2D hit = Physics2D.Raycast(transform.position, Vector2.right, 15, LayerMask.GetMask("Player")); // 15 DEJAR EN UNA VARIABLE DEPEDIENDO DEL TAMA�O DE PANTALLA
        return hit.collider != null;
    }

    bool CanSeePlayerOnLeft()
    {
        RaycastHit2D hit = Physics2D.Raycast(transform.position, Vector2.left, 15, LayerMask.GetMask("Player")); // 15 DEJAR EN UNA VARIABLE DEPEDIENDO DEL TAMA�O DE PANTALLA
        return hit.collider != null;
    }
}

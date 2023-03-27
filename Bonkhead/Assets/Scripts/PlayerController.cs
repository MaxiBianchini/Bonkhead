using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    public float speed;
    public float maxSpeed;
    public float forceJump;

    public bool canJump;
    public bool isOnGround;
    public bool isOnFloatingGround;

    public GameObject groundCast2D;

    private Rigidbody2D rigidBody2D;
    private SpriteRenderer spriteRenderer;

    [SerializeField] private float slopeLimit = 45f; // Ángulo máximo de la pendiente en grados
    [SerializeField] private float checkDistance = 1f; // Distancia a la que se comprueba si el objeto está en una pendiente


    // Start is called before the first frame update
    void Start()
    {
        rigidBody2D = GetComponent<Rigidbody2D>();
        spriteRenderer = GetComponent<SpriteRenderer>();

        canJump = false;
    }

    private void FixedUpdate()
    {
        checkGround();

/*
        RaycastHit2D hit = Physics2D.Raycast(transform.position, Vector2.down);
        if (hit.collider != null && hit.normal.y < -0.5f)
        {
            float angle = Vector2.Angle(hit.normal, Vector2.up);
            if (angle < pendienteAnguloMax && hit.distance < pendienteDistancia)
            {
                Debug.Log("Personaje está en una pendiente.");

            }
        }
*/
        RaycastHit2D hit = Physics2D.Raycast(groundCast2D.transform.position, Vector2.down, checkDistance);
       if (hit.collider != null && Vector2.Angle(hit.normal, Vector2.up) > slopeLimit)
       {
            if (hit.transform.tag == "Slope")
            {
                // Si está en una pendiente, anular la gravedad
                rigidBody2D.gravityScale = 0f;
                rigidBody2D.velocity = new Vector2(rigidBody2D.velocity.x, 0);
            }
            else
            {
                // Si no está en una pendiente, restaurar la gravedad
                rigidBody2D.gravityScale = 1f;
                rigidBody2D.velocity = new Vector2(rigidBody2D.velocity.x, rigidBody2D.velocity.y);

            }
       }
               


        Vector2 fixedVelocity = rigidBody2D.velocity;
        fixedVelocity.x *= 0.75f;

        if (isOnGround)
        {
            rigidBody2D.velocity = fixedVelocity;
        }

        float moveH = Input.GetAxis("Horizontal");
        rigidBody2D.AddForce(Vector2.right * moveH * speed);

        float limitSpeed = Mathf.Clamp(rigidBody2D.velocity.x, -maxSpeed, maxSpeed);
        rigidBody2D.velocity = new Vector2(limitSpeed, rigidBody2D.velocity.y);

        if (moveH > 0.01f)
        {
            spriteRenderer.flipX = false;
        }
        else if (moveH < -0.01f)
        {
            spriteRenderer.flipX = true;
        }

        if (canJump)
        {
            rigidBody2D.velocity = new Vector2(rigidBody2D.velocity.x, 0);
            rigidBody2D.AddForce(Vector2.up * forceJump, ForceMode2D.Impulse);
            canJump = false;
        }
    }



    // Update is called once per frame
    void Update()
    {
        if (Input.GetButtonDown("Jump") && isOnGround)
        {
            canJump = true;
        }
    }

    private void OnCollisionEnter2D(Collision2D collision)
    {
        if (collision.transform.tag == "Ground")
        {
            rigidBody2D.velocity = new Vector2(rigidBody2D.velocity.x, 0);
        }
    }

    private void checkGround()
    {
        RaycastHit2D colision = Physics2D.Raycast(groundCast2D.transform.position, Vector2.down, 1f);
        //Physics2D.Raycast(new Vector2(groundCast2D.transform.position.x, groundCast2D.transform.position.y), new Vector2(0, -1), 0.05f);

        if (colision.collider != null)
        {
            if (colision.transform.tag == "Ground")
            {
                isOnGround = true;
            }

            if (colision.transform.tag == "Floating Ground")
            {
                isOnGround = true;
                isOnFloatingGround = true;
            }
        }
        else
        { 
            isOnGround = false;
        }
    }
}

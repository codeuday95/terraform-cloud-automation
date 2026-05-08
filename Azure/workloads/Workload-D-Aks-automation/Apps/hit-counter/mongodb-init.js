db.createUser({
    user: "hit-counter-user",
    pwd: "hit-counter-password",
    roles: [
        {
            role: "readWrite",
            db: "hit-counter"
        }
    ]
});

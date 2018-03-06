const interceptar = (a, b) => {

    console.log("peguei login3", a, b);
};

const interceptar2 = (a, b)  => {

    console.log("peguei login ", a, b);
};

AccountsTemplates.configure({
    onSubmitHook : interceptar,
    postSignUpHook : interceptar2
});
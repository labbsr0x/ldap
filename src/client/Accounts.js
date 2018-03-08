
const interceptar = (a, b) => {

    console.log("peguei login", a, b);
};

const interceptar2 = (a, b)  => {

    console.log("peguei login 2 ", a, b);
};

AccountsTemplates.configure({
    onSubmitHook : interceptar,
    postSignUpHook : interceptar2
});

